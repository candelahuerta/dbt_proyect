"""
Orquestador de la carga diaria del proyecto TPCH con Prefect.

Prefect decide el orden y dbt Cloud ejecuta: el flujo lanza por API cada job
de dbt Cloud, espera a que termine y, solo si termina bien, lanza el siguiente.
Cada ejecución queda registrada y se ve de forma visual en Prefect Cloud.

Uso (desde una terminal con Prefect instalado y conectado a Prefect Cloud):
    python orquestacion/orquestador_prefect.py           -> carga diaria
    python orquestacion/orquestador_prefect.py semanal   -> full refresh semanal

Variables de entorno necesarias (nunca se escriben en el código):
    DBT_ACCESS_URL, DBT_ACCOUNT_ID, DBT_API_TOKEN
    DBT_JOB_00, DBT_JOB_01, DBT_JOB_02, DBT_JOB_03, DBT_JOB_05
"""

import os
import sys
import time

import httpx
from prefect import flow, get_run_logger, task

ACCESS_URL = os.environ["DBT_ACCESS_URL"].rstrip("/")
ACCOUNT_ID = os.environ["DBT_ACCOUNT_ID"]
API_TOKEN = os.environ["DBT_API_TOKEN"]

BASE_URL = f"{ACCESS_URL}/api/v2/accounts/{ACCOUNT_ID}"
CABECERAS = {
    "Authorization": f"Token {API_TOKEN}",
    "Content-Type": "application/json",
}

# Estado de una ejecución de dbt Cloud que significa "terminada correctamente"
ESTADO_CORRECTO = 10

# Tiempo máximo de espera por job, en segundos
ESPERA_MAXIMA = 60 * 60


@task
def ejecutar_job_dbt(nombre: str, job_id: str) -> int:
    """Lanza un job de dbt Cloud, espera a que termine y falla si no termina bien."""
    logger = get_run_logger()

    respuesta = httpx.post(
        f"{BASE_URL}/jobs/{job_id}/run/",
        headers=CABECERAS,
        json={"cause": f"Orquestado por Prefect: {nombre}"},
        timeout=30,
    )
    respuesta.raise_for_status()
    run_id = respuesta.json()["data"]["id"]
    logger.info(f"{nombre}: lanzado en dbt Cloud (ejecución {run_id})")

    inicio = time.time()
    while True:
        time.sleep(15)
        datos = httpx.get(
            f"{BASE_URL}/runs/{run_id}/", headers=CABECERAS, timeout=30
        ).json()["data"]
        logger.info(f"{nombre}: {datos['status_humanized']}")

        if datos["is_complete"]:
            duracion = round(time.time() - inicio)
            if datos["status"] != ESTADO_CORRECTO:
                raise RuntimeError(
                    f"{nombre} ha terminado con estado {datos['status_humanized']} "
                    f"tras {duracion} s. La cadena se detiene."
                )
            logger.info(f"{nombre}: terminado correctamente en {duracion} s")
            return run_id

        if time.time() - inicio > ESPERA_MAXIMA:
            raise TimeoutError(f"{nombre} no ha terminado en {ESPERA_MAXIMA} s")


@flow(name="Carga diaria TPCH")
def carga_diaria():
    """Frescura del origen -> staging y snapshots -> transformación -> reporting."""
    pasos = [
        ("00 - Frescura del origen", os.environ["DBT_JOB_00"]),
        ("01 - Staging y snapshots", os.environ["DBT_JOB_01"]),
        ("02 - Intermediate y business", os.environ["DBT_JOB_02"]),
        ("03 - Reporting", os.environ["DBT_JOB_03"]),
    ]
    # Se ejecutan en orden: si un paso falla, lanza un error y los siguientes no se ejecutan
    for nombre, job_id in pasos:
        ejecutar_job_dbt.with_options(name=nombre)(nombre, job_id)


@flow(name="Full refresh semanal TPCH")
def carga_semanal():
    """Recarga completa de los incrementales y de todo lo que depende de ellos."""
    nombre = "05 - Full refresh semanal"
    ejecutar_job_dbt.with_options(name=nombre)(nombre, os.environ["DBT_JOB_05"])


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "semanal":
        carga_semanal()
    else:
        carga_diaria()
