#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPOSITORY="${WORKSPACE}/repositorio"
SOURCE="${REPOSITORY}/areaperimetro.c"
PROGRAM="${REPOSITORY}/areaperimetro"
TEMP_DIR="$(mktemp -d)"
VALIDATION_PROGRAM="${TEMP_DIR}/areaperimetro"
PASSES=0
FAILURES=0

trap 'rm -rf -- "${TEMP_DIR}"' EXIT

pass() {
    printf 'PASS: %s\n' "$1"
    PASSES=$((PASSES + 1))
}

fail() {
    printf 'FAIL: %s\n' "$1"
    FAILURES=$((FAILURES + 1))
}

check() {
    local description="$1"
    shift

    if "$@"; then
        pass "${description}"
    else
        fail "${description}"
    fi
}

repository_exists() {
    [[ -d "${REPOSITORY}/.git" ]] || return 1
    git -C "${REPOSITORY}" rev-parse --is-inside-work-tree \
        >/dev/null 2>&1
}

identity_is_configured() {
    local name=""
    local email=""

    repository_exists || return 1
    name="$(git -C "${REPOSITORY}" config user.name 2>/dev/null)"
    email="$(git -C "${REPOSITORY}" config user.email 2>/dev/null)"
    [[ -n "${name}" && -n "${email}" ]]
}

origin_uses_ssh() {
    local origin=""

    repository_exists || return 1
    origin="$(git -C "${REPOSITORY}" remote get-url origin 2>/dev/null)"
    [[ "${origin}" == git@github.com:* || \
       "${origin}" == git@gitlab.inf.utfsm.cl:* ]]
}

file_is_tracked() {
    local path="$1"

    repository_exists || return 1
    git -C "${REPOSITORY}" ls-files --error-unmatch -- "${path}" \
        >/dev/null 2>&1
}

readme_has_required_content() {
    [[ -f "${REPOSITORY}/README.md" ]] || return 1
    grep -Fxq 'Este repositorio contiene un programa en C que calcula el área y el perímetro de un círculo.' \
        "${REPOSITORY}/README.md" || return 1
    grep -Fxq 'Última revisión remota: completada.' \
        "${REPOSITORY}/README.md"
}

is_binary_executable() {
    local path="$1"
    local description=""

    [[ -f "${path}" && -x "${path}" ]] || return 1
    description="$(file -b -- "${path}")"
    [[ "${description}" == ELF*executable* ]]
}

program_produces_expected_output() {
    is_binary_executable "${PROGRAM}" || return 1
    [[ "$("${PROGRAM}" 2>/dev/null <<<'5')" == \
       $'Área: 78.54\nPerímetro: 31.42' ]]
}

source_compiles_cleanly() {
    command -v gcc >/dev/null 2>&1 || return 1
    [[ -f "${SOURCE}" ]] || return 1
    gcc -Wall -Wextra -Werror -std=c11 "${SOURCE}" \
        -o "${VALIDATION_PROGRAM}" >/dev/null 2>&1 || return 1
    [[ "$("${VALIDATION_PROGRAM}" 2>/dev/null <<<'5')" == \
       $'Área: 78.54\nPerímetro: 31.42' ]]
}

executable_is_ignored() {
    [[ -f "${PROGRAM}" ]] || return 1
    file_is_tracked .gitignore || return 1
    if file_is_tracked areaperimetro; then
        return 1
    fi
    git -C "${REPOSITORY}" check-ignore -q -- areaperimetro
}

source_has_initial_and_corrected_versions() {
    local count=""

    repository_exists || return 1
    count="$(git -C "${REPOSITORY}" log --format='%H' \
        -- areaperimetro.c 2>/dev/null | wc -l)" || return 1
    [[ "${count}" =~ ^[[:space:]]*[0-9]+[[:space:]]*$ ]] || return 1
    (( count >= 2 ))
}

history_has_expected_cycles() {
    local count=""

    repository_exists || return 1
    count="$(git -C "${REPOSITORY}" rev-list --count HEAD \
        2>/dev/null)" || return 1
    [[ "${count}" =~ ^[0-9]+$ ]] || return 1
    (( count >= 5 ))
}

repository_is_clean() {
    local status=""

    repository_exists || return 1
    status="$(git -C "${REPOSITORY}" status --porcelain \
        --untracked-files=all 2>/dev/null)"
    [[ -z "${status}" ]]
}

repository_is_synchronized() {
    local local_commit=""
    local remote_commit=""

    repository_exists || return 1
    git -C "${REPOSITORY}" rev-parse --abbrev-ref \
        --symbolic-full-name '@{upstream}' >/dev/null 2>&1 || return 1
    local_commit="$(git -C "${REPOSITORY}" rev-parse HEAD \
        2>/dev/null)" || return 1
    remote_commit="$(git -C "${REPOSITORY}" rev-parse '@{upstream}' \
        2>/dev/null)" || return 1
    [[ "${local_commit}" == "${remote_commit}" ]]
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio GIT   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'

check "[1.1] La identidad de Git está configurada" identity_is_configured
check "[2.2] Existe el repositorio clonado" repository_exists
check "[2.2] El remote origin utiliza una URL SSH conocida" origin_uses_ssh
check "[3.3] README.md está registrado en Git" file_is_tracked README.md
check "[3.3] areaperimetro.c está registrado en Git" file_is_tracked areaperimetro.c
check "[4.1] areaperimetro existe como binario ejecutable" is_binary_executable "${PROGRAM}"
check "[4.2] .gitignore está registrado en Git" file_is_tracked .gitignore
check "[4.2] areaperimetro existe como archivo ignored (ignorado)" executable_is_ignored
check "[4.3] areaperimetro produce el resultado esperado" program_produces_expected_output
check "[4.3] areaperimetro.c compila sin warnings" source_compiles_cleanly
check "[4.4] areaperimetro.c tiene una versión inicial y una corregida" source_has_initial_and_corrected_versions
check "[6] README.md contiene el cambio creado en el remote" readme_has_required_content
check "[6] La historia contiene los ciclos solicitados" history_has_expected_cycles
check "[6] El local está sincronizado con origin" repository_is_synchronized
check "[6] El repositorio no tiene cambios pendientes" repository_is_clean
check "[7] check.sh tiene permiso de ejecución" test -x "${SCRIPT_DIR}/check.sh"

printf '\n== Resumen ===============================\n\n'
TOTAL=$((PASSES + FAILURES))
COUNT_WIDTH=${#TOTAL}
printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${COUNT_WIDTH}" "${PASSES}"
printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${COUNT_WIDTH}" "${FAILURES}"

if (( FAILURES == 0 )); then
    exit 0
fi

exit 1
