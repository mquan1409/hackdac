#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIMULATE_SH="${SCRIPT_DIR}/simulate.sh"

STOP_ON_FAIL=0

usage() {
    cat <<EOF
Usage: $0 [--stop-on-fail]

Runs the selected Caliptra tests sequentially through scripts/simulate.sh.

Options:
  --stop-on-fail  Stop immediately after the first failing test.
  -h, --help      Show this help message.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stop-on-fail)
            STOP_ON_FAIL=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ ! -x "${SIMULATE_SH}" ]]; then
    echo "ERROR: simulate.sh is not executable: ${SIMULATE_SH}" >&2
    exit 1
fi

TESTS=(
    rand_test_dma
    randomized_mldsa_invalid_verify
    randomized_mlkem_kv
    randomized_pcr_ecc_signing
    randomized_pcr_mldsa_signing
    smoke_test_abr_kv_zero_error
    smoke_test_aes_gcm
    smoke_test_aes_kv_out_rand
    smoke_test_aes_kv_rand
    smoke_test_ahb_mux
    smoke_test_cg_wdt
    smoke_test_clk_gating
    smoke_test_cshake
    smoke_test_datavault_basic
    smoke_test_datavault_lock
    smoke_test_datavault_mini
    smoke_test_datavault_reset
    smoke_test_dma
    smoke_test_dma_aes_gcm
    smoke_test_dma_aes_gcm_collision_test
    smoke_test_dma_aes_gcm_long
    smoke_test_dma_aes_gcm_non_gcm_en_dec
    smoke_test_dma_aes_gcm_rd_enc_axi_err
    smoke_test_dma_aes_gcm_short_1_dword
    smoke_test_dma_aes_gcm_short_dword
    smoke_test_dma_aes_gcm_wr_enc_axi_err
    smoke_test_dma_aes_kv
    smoke_test_doe_cg
    smoke_test_doe_kv_ocp_progress
    smoke_test_doe_rand
    smoke_test_doe_scan
    smoke_test_ecc_errortrigger1
    smoke_test_ecc_errortrigger2
    smoke_test_ecc_errortrigger3
    smoke_test_ecc_errortrigger4
    smoke_test_ecc_flow1_kv_ocp_progress
    smoke_test_ecc_flow2_kv_ocp_progress
    smoke_test_ecc_keygen
    smoke_test_ecc_sign
    smoke_test_ecc_verify
    smoke_test_ecdh
    smoke_test_fw_kv_backtoback_hmac
    smoke_test_hek_flow
    smoke_test_hmac
    smoke_test_hmac_errortrigger
    smoke_test_hmac_kv_ocp_progress
    smoke_test_hw_config
    smoke_test_iccm_reset
    smoke_test_kv
    smoke_test_kv_cg
    smoke_test_kv_crypto_flow
    smoke_test_kv_crypto_flow2
    smoke_test_kv_doe
    smoke_test_kv_ecc_flow1
    smoke_test_kv_ecc_flow2
    smoke_test_kv_ecdh_flow
    smoke_test_kv_hmac_flow
    smoke_test_kv_hmac_multiblock_flow
    smoke_test_kv_lock_use_mid_read
    smoke_test_kv_mldsa
    smoke_test_kv_mlkem
    smoke_test_kv_parallel_access
    smoke_test_kv_rules_ocp_lock
    smoke_test_kv_securitystate
    smoke_test_kv_swwe_lock
    smoke_test_kv_uds_reset
    smoke_test_kv_write_scan_mode
    smoke_test_mbox
    smoke_test_mbox_byte_read
    smoke_test_mbox_cg
    smoke_test_mldsa
    smoke_test_mldsa_all_zero_seed
    smoke_test_mldsa_edge
    smoke_test_mldsa_errortrigger
    smoke_test_mldsa_externalmu
    smoke_test_mldsa_externalmu_keygen_sign_vfy_rand
    smoke_test_mldsa_keygen_sign_vfy_rand
    smoke_test_mldsa_keygen_standalone_sign_vfy_rand
    smoke_test_mldsa_kv_ocp_progress
    smoke_test_mldsa_locked_api
    smoke_test_mldsa_zeroize
    smoke_test_mlkem
    smoke_test_mlkem_all_zero_seed
    smoke_test_mlkem_errortrigger
    smoke_test_mlkem_kv_endian
    smoke_test_mlkem_kv_ocp_progress
    smoke_test_mlkem_locked_api
    smoke_test_mlkem_shared_key
    smoke_test_pcr_signing
    smoke_test_pcr_zeroize
    smoke_test_ras
    smoke_test_sha256
    smoke_test_sha256_wntz
    smoke_test_sha256_wntz_rand
    smoke_test_sha3
    smoke_test_sha3_externalmu
    smoke_test_sha3_interrupt
    smoke_test_sha3_regs
    smoke_test_sha512
    smoke_test_sha512_restore
    smoke_test_sha_accel
    smoke_test_sram_ecc
    smoke_test_strap
    smoke_test_trng
    smoke_test_veer
    smoke_test_wdt
    smoke_test_wdt_rst
    smoke_test_zeroize_crypto
)

LOG_DIR="${REPO_ROOT}/logs"
SUMMARY_FILE="${LOG_DIR}/summary.txt"
mkdir -p "${LOG_DIR}"
: > "${SUMMARY_FILE}"

passed=()
failed=()
total="${#TESTS[@]}"

echo "Running ${total} tests sequentially"
echo "Logs: ${LOG_DIR}"
echo "Summary: ${SUMMARY_FILE}"
echo

for i in "${!TESTS[@]}"; do
    test_name="${TESTS[$i]}"
    test_num="$((i + 1))"
    log_file="${LOG_DIR}/${test_name}.log"

    echo "[$test_num/${total}] START ${test_name}"
    if "${SIMULATE_SH}" --test "${test_name}" 2>&1 | tee "${log_file}"; then
        passed+=("${test_name}")
        result_line="[$test_num/${total}] PASS ${test_name}"
        echo "${result_line}"
        echo "${result_line}" >> "${SUMMARY_FILE}"
    else
        status=$?
        failed+=("${test_name}")
        result_line="[$test_num/${total}] FAIL ${test_name} (exit ${status})"
        echo "${result_line}"
        echo "${result_line}" >> "${SUMMARY_FILE}"
        if [[ "${STOP_ON_FAIL}" -eq 1 ]]; then
            break
        fi
    fi
    echo
done

{
    echo
    echo "Total selected: ${total}"
    echo "Passed: ${#passed[@]}"
    echo "Failed: ${#failed[@]}"
    echo
    echo "Passed tests:"
    printf '  %s\n' "${passed[@]}"
    echo
    echo "Failed tests:"
    printf '  %s\n' "${failed[@]}"
} | tee -a "${SUMMARY_FILE}"

echo
echo "Summary: ${SUMMARY_FILE}"

if [[ "${#failed[@]}" -gt 0 ]]; then
    exit 1
fi

exit 0
