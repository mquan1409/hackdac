# Smoke Test To RTL Mapping Report

Generated from repository inspection on 2026-06-28.

## Scope

This report maps the 103 `smoke_test_*` entries listed in `smoke_tests_available.md` to the RTL blocks and representative RTL modules they exercise.

Important interpretation:

- The smoke YAML files under `hack_dac_26/third_party/caliptra-rtl/src/integration/test_suites/*/*.yml` do not directly name RTL modules, tops, or filelists. They contain test metadata such as `seed`, `testname`, optional `plusargs`, and rare `description` fields.
- All listed smoke tests are integration tests that build through the shared Caliptra top-level simulation target from `src/integration/config/compile.yml`: `caliptra_top_tb` over `caliptra_top`.
- Therefore, the per-test mapping below means "RTL primarily targeted or exercised by the test source/register activity", not "the only RTL compiled for that test".

## Common RTL Compiled For All Listed Smoke Tests

Every listed test runs through the integration top:

| Label | Representative RTL modules | Representative RTL files |
|---|---|---|
| `TOP` | `caliptra_top` | `hack_dac_26/third_party/caliptra-rtl/src/integration/rtl/caliptra_top.sv` |
| `SOC_IFC` | `soc_ifc_top`, `soc_ifc_reg`, `soc_ifc_arb`, `soc_ifc_boot_fsm` | `hack_dac_26/third_party/caliptra-rtl/src/soc_ifc/rtl/*.sv` |

## RTL Block Reference

The per-test table uses these block labels. The modules listed here are representative top/control/register/datapath modules from the repo's RTL/config structure.

| Label | Representative RTL modules | Representative RTL files |
|---|---|---|
| `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `abr_mem_top`, `abr_reg`, `ntt_top`, `abr_sha3`, `abr_sampler_top`, `compress_top`, `decompress_top` | `submodules/adams-bridge/src/abr_top/rtl/*.sv`, `submodules/adams-bridge/src/ntt_top/rtl/ntt_top.sv`, `submodules/adams-bridge/src/abr_sha3/rtl/abr_sha3.sv` |
| `AES` | `aes_clp_wrapper`, `aes`, `aes_core`, `aes_ghash`, `aes_cipher_core` | `src/aes/rtl/aes_clp_wrapper.sv`, `src/aes/rtl/aes.sv`, `src/aes/rtl/aes_core.sv`, `src/aes/rtl/aes_ghash.sv`, `src/aes/rtl/aes_cipher_core.sv` |
| `AHB` | `ahb_lite_bus`, `ahb_lite_2to1_mux`, `ahb_lite_address_decoder`, `ahb_sif`, `axi_slv` | `src/ahb_lite_bus/rtl/*.sv`, `src/integration/rtl/ahb_sif.sv` |
| `CLK` | `clk_gate`, Caliptra ICG logic, clock-gating controls in `caliptra_top` and `soc_ifc_reg` | `src/libs/rtl/clk_gate.sv`, `src/libs/rtl/caliptra_icg.sv`, `src/integration/rtl/caliptra_top.sv` |
| `CSRNG/TRNG` | `csrng`, `entropy_src` | `src/csrng/rtl/csrng.sv`, `src/entropy_src/rtl/entropy_src.sv` |
| `DMA` | `axi_dma_top`, `axi_dma_ctrl`, `axi_dma_reg`, `axi_sub` | `src/axi/rtl/axi_dma_top.sv`, `src/axi/rtl/axi_dma_ctrl.sv`, `src/axi/rtl/axi_dma_reg.sv`, `src/axi/rtl/axi_sub.sv` |
| `DOE` | `doe_ctrl`, `doe_cbc`, `doe_core_cbc`, `doe_reg`, `doe_key_mem` | `src/doe/rtl/*.sv` |
| `DV` | `dv`, `dv_reg` | `src/datavault/rtl/dv.sv`, `src/datavault/rtl/dv_reg.sv` |
| `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_pm_ctrl`, `ecc_arith_unit`, `ecc_reg`, `hmac_drbg` | `src/ecc/rtl/*.sv`, `src/hmac_drbg/rtl/hmac_drbg.sv` |
| `HMAC` | `hmac_ctrl`, `hmac`, `hmac_core`, `hmac_reg` | `src/hmac/rtl/*.sv` |
| `KV` | `kv`, `kv_fsm`, `kv_read_client`, `kv_write_client`, `kv_reg` | `src/keyvault/rtl/*.sv` |
| `MBOX` | `mbox`, `mbox_csr` | `src/soc_ifc/rtl/mbox.sv`, `src/soc_ifc/rtl/mbox_csr.sv` |
| `PV` | `pv`, `pv_gen_hash`, `pv_reg` | `src/pcrvault/rtl/pv.sv`, `src/pcrvault/rtl/pv_gen_hash.sv`, `src/pcrvault/rtl/pv_reg.sv` |
| `SHA256` | `sha256_ctrl`, `sha256`, `sha256_core`, `sha256_reg` | `src/sha256/rtl/*.sv`, `src/sha256/rtl/sha256_core.v` |
| `SHA512` | `sha512_ctrl`, `sha512`, `sha512_core`, `sha512_reg` | `src/sha512/rtl/*.sv`, `src/sha512/rtl/sha512_core.v` |
| `SHA512_ACC` | `sha512_acc_top`, `sha512_acc_csr`, `sha512_core` | `src/soc_ifc/rtl/sha512_acc_top.sv`, `src/soc_ifc/rtl/sha512_acc_csr.sv`, `src/sha512/rtl/sha512_core.v` |
| `SHA3/KMAC` | `sha3_ctrl`, `kmac`, `kmac_core`, `ot_sha3`, `ot_keccak_2share`, `ot_keccak_round` | `src/sha3/rtl/*.sv` |
| `VeeR/JTAG` | `el2_veer_wrapper`, `el2_veer`, `el2_dbg`, `rvjtag_tap`, `dmi_wrapper` | `src/riscv_core/veer_el2/rtl/*.sv`, `src/riscv_core/veer_el2/rtl/dmi/*.v` |
| `WDT` | `wdt`, WDT control/status in `soc_ifc_reg` | `src/soc_ifc/rtl/wdt.sv`, `src/soc_ifc/rtl/soc_ifc_reg.sv` |

## Per-Test Mapping

Confidence:

- `High`: test name and source/register usage point at the same block.
- `Medium`: scenario-style test that intentionally combines blocks or targets top-level control behavior.

| Smoke test | Mapped RTL block labels | Representative RTL modules | Basis / note | Confidence |
|---|---|---|---|---|
| `smoke_test_abr_kv_zero_error` | `ABR`, `KV` | `abr_top`, `abr_ctrl`, `kv`, `kv_read_client`, `kv_write_client` | MLDSA/MLKEM ABR flow through key-vault error path. | High |
| `smoke_test_aes_gcm` | `AES` | `aes_clp_wrapper`, `aes`, `aes_core`, `aes_ghash` | Direct AES-GCM smoke. | High |
| `smoke_test_aes_kv_out_rand` | `AES`, `KV` | `aes_clp_wrapper`, `aes_ghash`, `kv`, `kv_read_client`, `kv_write_client` | AES GCM with key-vault output/randomized path. | High |
| `smoke_test_aes_kv_rand` | `AES`, `KV` | `aes_clp_wrapper`, `aes_core`, `aes_ghash`, `kv` | AES key-vault randomized path. | High |
| `smoke_test_ahb_mux` | `AHB`, `SOC_IFC` | `ahb_lite_bus`, `ahb_lite_2to1_mux`, `ahb_sif`, `soc_ifc_top` | AHB mux/integration bus path. | High |
| `smoke_test_cg_wdt` | `CLK`, `WDT`, `SOC_IFC` | `clk_gate`, `wdt`, `soc_ifc_reg` | Clock-gating plus watchdog timer behavior. | High |
| `smoke_test_clk_gating` | `CLK`, `SOC_IFC` | `clk_gate`, `caliptra_top`, `soc_ifc_reg` | Clock-gating control path. | High |
| `smoke_test_cshake` | `SHA3/KMAC` | `sha3_ctrl`, `kmac`, `kmac_core`, `ot_sha3` | cSHAKE is handled by SHA3/KMAC RTL. | High |
| `smoke_test_datavault_basic` | `DV` | `dv`, `dv_reg` | Data vault basic register/data path. | High |
| `smoke_test_datavault_lock` | `DV` | `dv`, `dv_reg` | Data vault lock behavior. | High |
| `smoke_test_datavault_mini` | `DV` | `dv`, `dv_reg` | Data vault mini flow. | High |
| `smoke_test_datavault_reset` | `DV`, `SOC_IFC` | `dv`, `dv_reg`, `soc_ifc_reg` | Data vault reset scenario through top-level reset/control. | Medium |
| `smoke_test_dma` | `DMA`, `SOC_IFC` | `axi_dma_top`, `axi_dma_ctrl`, `axi_dma_reg`, `soc_ifc_top` | Direct DMA smoke. | High |
| `smoke_test_dma_aes_gcm` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `aes_clp_wrapper`, `aes_ghash` | DMA path into AES-GCM. | High |
| `smoke_test_dma_aes_gcm_collision_test` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `axi_dma_reg`, `aes_clp_wrapper` | DMA/AES collision and error-status path. | High |
| `smoke_test_dma_aes_gcm_long` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `aes_clp_wrapper`, `aes_ghash` | Long DMA AES-GCM transfer. | High |
| `smoke_test_dma_aes_gcm_non_gcm_en_dec` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `aes_clp_wrapper`, `aes` | DMA AES non-GCM encrypt/decrypt mode. | High |
| `smoke_test_dma_aes_gcm_rd_enc_axi_err` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `axi_dma_reg`, `aes_clp_wrapper` | DMA AES read/encrypt AXI error path. | High |
| `smoke_test_dma_aes_gcm_short_1_dword` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `aes_clp_wrapper`, `aes_ghash` | Short DMA AES-GCM transfer. | High |
| `smoke_test_dma_aes_gcm_short_dword` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `aes_clp_wrapper`, `aes_ghash` | Short dword DMA AES-GCM transfer. | High |
| `smoke_test_dma_aes_gcm_wr_enc_axi_err` | `DMA`, `AES` | `axi_dma_top`, `axi_dma_ctrl`, `axi_dma_reg`, `aes_clp_wrapper` | DMA AES write/encrypt AXI error path. | High |
| `smoke_test_dma_aes_kv` | `DMA`, `AES`, `KV` | `axi_dma_top`, `axi_dma_ctrl`, `aes_clp_wrapper`, `kv` | DMA AES path with key-vault key access. | High |
| `smoke_test_doe_cg` | `DOE`, `CLK`, `SOC_IFC` | `doe_ctrl`, `doe_cbc`, `doe_reg`, `clk_gate`, `soc_ifc_reg` | DOE with clock-gating behavior. | High |
| `smoke_test_doe_kv_ocp_progress` | `DOE`, `KV`, `SOC_IFC` | `doe_ctrl`, `doe_key_mem`, `kv`, `soc_ifc_reg` | DOE key-vault path with OCP lock/progress controls. | High |
| `smoke_test_doe_rand` | `DOE` | `doe_ctrl`, `doe_cbc`, `doe_core_cbc`, `doe_key_mem` | Direct DOE randomized flow. | High |
| `smoke_test_doe_scan` | `DOE`, `SOC_IFC` | `doe_ctrl`, `doe_reg`, `soc_ifc_reg` | DOE scan-mode scenario. | High |
| `smoke_test_ecc_errortrigger1` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_reg` | ECC error-trigger path. | High |
| `smoke_test_ecc_errortrigger2` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_reg` | ECC error-trigger path. | High |
| `smoke_test_ecc_errortrigger3` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_pm_ctrl`, `ecc_reg` | ECC error-trigger path. | High |
| `smoke_test_ecc_errortrigger4` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_pm_ctrl`, `ecc_reg` | ECC error-trigger path. | High |
| `smoke_test_ecc_flow1_kv_ocp_progress` | `ECC`, `KV`, `SOC_IFC` | `ecc_top`, `ecc_dsa_ctrl`, `kv`, `soc_ifc_reg` | ECC key-vault flow with OCP progress controls. | High |
| `smoke_test_ecc_flow2_kv_ocp_progress` | `ECC`, `KV`, `SOC_IFC` | `ecc_top`, `ecc_dsa_ctrl`, `kv`, `soc_ifc_reg` | ECC key-vault flow with OCP progress controls. | High |
| `smoke_test_ecc_keygen` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_pm_ctrl`, `hmac_drbg` | ECC key generation. | High |
| `smoke_test_ecc_sign` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_arith_unit`, `hmac_drbg` | ECC signing flow. | High |
| `smoke_test_ecc_verify` | `ECC` | `ecc_top`, `ecc_dsa_ctrl`, `ecc_arith_unit`, `ecc_reg` | ECC verification flow. | High |
| `smoke_test_ecdh` | `ECC` | `ecc_top`, `ecc_pm_ctrl`, `ecc_arith_unit`, `ecc_reg` | ECDH uses the ECC point-multiply path. | High |
| `smoke_test_fw_kv_backtoback_hmac` | `HMAC`, `KV` | `hmac_ctrl`, `hmac`, `hmac_core`, `kv` | Back-to-back HMAC using key-vault path. | High |
| `smoke_test_hek_flow` | `SOC_IFC` | `soc_ifc_top`, `soc_ifc_reg` | HEK/OCP-style top-level hardware-config flow; source references SOC_IFC HW config rather than a standalone HEK RTL module. | Medium |
| `smoke_test_hmac` | `HMAC` | `hmac_ctrl`, `hmac`, `hmac_core`, `hmac_reg` | Direct HMAC smoke. | High |
| `smoke_test_hmac_errortrigger` | `HMAC` | `hmac_ctrl`, `hmac`, `hmac_core`, `hmac_reg` | HMAC error-trigger path. | High |
| `smoke_test_hmac_kv_ocp_progress` | `HMAC`, `KV`, `SOC_IFC` | `hmac_ctrl`, `hmac_core`, `kv`, `soc_ifc_reg` | HMAC key-vault path with OCP progress controls. | High |
| `smoke_test_hw_config` | `SOC_IFC` | `soc_ifc_top`, `soc_ifc_reg` | Hardware configuration register path. | High |
| `smoke_test_iccm_reset` | `VeeR/JTAG`, `SOC_IFC` | `el2_veer_wrapper`, `el2_veer`, `soc_ifc_reg` | ICCM/core reset scenario. | Medium |
| `smoke_test_kv` | `KV` | `kv`, `kv_fsm`, `kv_read_client`, `kv_write_client`, `kv_reg` | Direct key-vault smoke. | High |
| `smoke_test_kv_cg` | `KV`, `CLK`, `SOC_IFC` | `kv`, `kv_fsm`, `clk_gate`, `soc_ifc_reg` | Key-vault clock-gating scenario. | High |
| `smoke_test_kv_crypto_flow` | `KV`, `DOE`, `ECC`, `HMAC`, `ABR` | `kv`, `doe_ctrl`, `ecc_top`, `hmac_ctrl`, `abr_top` | Combined key-vault crypto-client flow; source references DOE, ECC, HMAC, and MLDSA/ABR paths. | High |
| `smoke_test_kv_crypto_flow2` | `KV`, `DOE`, `ECC`, `HMAC`, `ABR` | `kv`, `doe_ctrl`, `ecc_top`, `hmac_ctrl`, `abr_top` | Second combined key-vault crypto-client flow. | High |
| `smoke_test_kv_doe` | `KV`, `DOE` | `kv`, `kv_read_client`, `kv_write_client`, `doe_ctrl`, `doe_key_mem` | Key-vault path for DOE. | High |
| `smoke_test_kv_ecc_flow1` | `KV`, `ECC` | `kv`, `ecc_top`, `ecc_dsa_ctrl` | Key-vault path for ECC flow 1. | High |
| `smoke_test_kv_ecc_flow2` | `KV`, `ECC` | `kv`, `ecc_top`, `ecc_dsa_ctrl` | Key-vault path for ECC flow 2. | High |
| `smoke_test_kv_ecdh_flow` | `KV`, `ECC` | `kv`, `ecc_top`, `ecc_pm_ctrl` | Key-vault path for ECDH point-multiply flow. | High |
| `smoke_test_kv_hmac_flow` | `KV`, `HMAC` | `kv`, `hmac_ctrl`, `hmac_core` | Key-vault path for HMAC. | High |
| `smoke_test_kv_hmac_multiblock_flow` | `KV`, `HMAC` | `kv`, `hmac_ctrl`, `hmac_core` | Key-vault HMAC multiblock flow. | High |
| `smoke_test_kv_lock_use_mid_read` | `KV` | `kv`, `kv_fsm`, `kv_read_client`, `kv_reg` | Key-vault lock during read path. | High |
| `smoke_test_kv_mldsa` | `KV`, `ABR` | `kv`, `abr_top`, `abr_ctrl` | Key-vault path for MLDSA in Adams Bridge. | High |
| `smoke_test_kv_mlkem` | `KV`, `ABR` | `kv`, `abr_top`, `abr_ctrl` | Key-vault path for MLKEM in Adams Bridge. | High |
| `smoke_test_kv_parallel_access` | `KV`, `AES`, `HMAC`, `ECC`, `DOE`, `ABR` | `kv`, `aes_clp_wrapper`, `hmac_ctrl`, `ecc_top`, `doe_ctrl`, `abr_top` | Parallel key-vault access by multiple crypto clients. | High |
| `smoke_test_kv_rules_ocp_lock` | `KV`, `SOC_IFC` | `kv`, `kv_read_rule_check`, `kv_write_rule_check`, `soc_ifc_reg` | Key-vault rule checks under OCP lock/security state. | High |
| `smoke_test_kv_securitystate` | `KV`, `SOC_IFC` | `kv`, `kv_fsm`, `kv_reg`, `soc_ifc_reg` | Key-vault security-state behavior. | High |
| `smoke_test_kv_swwe_lock` | `KV` | `kv`, `kv_fsm`, `kv_write_client`, `kv_reg` | Key-vault software write-enable lock path. | High |
| `smoke_test_kv_uds_reset` | `KV`, `DOE`, `SOC_IFC` | `kv`, `doe_ctrl`, `doe_key_mem`, `soc_ifc_reg` | UDS/DOE secret path and key-vault reset scenario. | Medium |
| `smoke_test_kv_write_scan_mode` | `KV`, `SOC_IFC` | `kv`, `kv_write_client`, `kv_reg`, `soc_ifc_reg` | Key-vault write behavior in scan mode. | High |
| `smoke_test_mbox` | `MBOX`, `SOC_IFC` | `mbox`, `mbox_csr`, `soc_ifc_top` | Direct mailbox smoke. | High |
| `smoke_test_mbox_byte_read` | `MBOX`, `SOC_IFC` | `mbox`, `mbox_csr`, `soc_ifc_top` | Mailbox byte-read path. | High |
| `smoke_test_mbox_cg` | `MBOX`, `CLK`, `SOC_IFC` | `mbox`, `mbox_csr`, `clk_gate`, `soc_ifc_reg` | Mailbox clock-gating scenario. | High |
| `smoke_test_mldsa` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `ntt_top`, `abr_sha3` | MLDSA is implemented in Adams Bridge RTL. | High |
| `smoke_test_mldsa_all_zero_seed` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `abr_sampler_top` | MLDSA all-zero seed scenario. | High |
| `smoke_test_mldsa_edge` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `ntt_top` | MLDSA edge-case flow. | High |
| `smoke_test_mldsa_errortrigger` | `ABR` | `abr_top`, `abr_ctrl`, `abr_reg` | MLDSA error-trigger path. | High |
| `smoke_test_mldsa_externalmu` | `ABR` | `abr_top`, `abr_ctrl`, `abr_sha3` | MLDSA external-mu path inside Adams Bridge. | High |
| `smoke_test_mldsa_externalmu_keygen_sign_vfy_rand` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `abr_sha3`, `ntt_top` | MLDSA external-mu keygen/sign/verify randomized flow. | High |
| `smoke_test_mldsa_keygen_sign_vfy_rand` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `ntt_top`, `abr_sampler_top` | MLDSA keygen/sign/verify randomized flow. | High |
| `smoke_test_mldsa_keygen_standalone_sign_vfy_rand` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `ntt_top` | MLDSA standalone keygen/sign/verify flow. | High |
| `smoke_test_mldsa_kv_ocp_progress` | `ABR`, `KV`, `SOC_IFC` | `abr_top`, `abr_ctrl`, `kv`, `soc_ifc_reg` | MLDSA key-vault path with OCP progress controls. | High |
| `smoke_test_mldsa_locked_api` | `ABR`, `SOC_IFC` | `abr_top`, `abr_ctrl`, `abr_reg`, `soc_ifc_reg` | MLDSA locked API behavior. | High |
| `smoke_test_mldsa_zeroize` | `ABR` | `abr_top`, `abr_ctrl`, `abr_reg`, `abr_mem_top` | MLDSA zeroization path. | High |
| `smoke_test_mlkem` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `abr_mem_top` | MLKEM path is integrated through Adams Bridge RTL. | High |
| `smoke_test_mlkem_all_zero_seed` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `abr_sampler_top` | MLKEM all-zero seed scenario. | High |
| `smoke_test_mlkem_errortrigger` | `ABR` | `abr_top`, `abr_ctrl`, `abr_reg` | MLKEM error-trigger path. | High |
| `smoke_test_mlkem_kv_endian` | `ABR`, `KV` | `abr_top`, `abr_ctrl`, `kv`, `kv_read_client` | MLKEM key-vault endian behavior. | High |
| `smoke_test_mlkem_kv_ocp_progress` | `ABR`, `KV`, `SOC_IFC` | `abr_top`, `abr_ctrl`, `kv`, `soc_ifc_reg` | MLKEM key-vault path with OCP progress controls. | High |
| `smoke_test_mlkem_locked_api` | `ABR`, `SOC_IFC` | `abr_top`, `abr_ctrl`, `abr_reg`, `soc_ifc_reg` | MLKEM locked API behavior. | High |
| `smoke_test_mlkem_shared_key` | `ABR` | `abr_top`, `abr_ctrl`, `abr_seq`, `abr_mem_top` | MLKEM shared-key flow. | High |
| `smoke_test_pcr_signing` | `PV`, `ECC`, `SHA512` | `pv`, `pv_gen_hash`, `ecc_top`, `sha512_core` | PCR vault signing path: PCR hash/signing flow with ECC/SHA512 involvement. | High |
| `smoke_test_pcr_zeroize` | `PV`, `SOC_IFC` | `pv`, `pv_reg`, `soc_ifc_reg` | PCR vault zeroization/reset-control scenario. | Medium |
| `smoke_test_ras` | `SOC_IFC`, `MBOX`, `DMA`, `VeeR/JTAG`, `ECC` | `soc_ifc_reg`, `mbox`, `axi_dma_top`, `el2_veer`, `ecc_top` | RAS/error-injection scenario covers interrupt/error paths, ICCM/SRAM, mailbox, DMA, and ECC-facing status. | Medium |
| `smoke_test_sha256` | `SHA256` | `sha256_ctrl`, `sha256`, `sha256_core`, `sha256_reg` | Direct SHA256 smoke. | High |
| `smoke_test_sha256_wntz` | `SHA256` | `sha256_ctrl`, `sha256`, `sha256_core`, `sha256_reg` | SHA256 WNTZ variant. | High |
| `smoke_test_sha256_wntz_rand` | `SHA256` | `sha256_ctrl`, `sha256`, `sha256_core`, `sha256_reg` | Randomized SHA256 WNTZ variant. | High |
| `smoke_test_sha3` | `SHA3/KMAC` | `sha3_ctrl`, `kmac`, `kmac_core`, `ot_sha3` | Direct SHA3/KMAC smoke. | High |
| `smoke_test_sha3_externalmu` | `SHA3/KMAC`, `ABR` | `sha3_ctrl`, `kmac_core`, `ot_sha3`, `abr_top` | SHA3 external-mu scenario used with MLDSA context. | Medium |
| `smoke_test_sha3_interrupt` | `SHA3/KMAC` | `sha3_ctrl`, `kmac`, `kmac_core`, `ot_sha3` | SHA3/KMAC interrupt path. | High |
| `smoke_test_sha3_regs` | `SHA3/KMAC` | `sha3_ctrl`, `kmac_reg_top`, `kmac`, `ot_sha3` | SHA3/KMAC register path. | High |
| `smoke_test_sha512` | `SHA512` | `sha512_ctrl`, `sha512`, `sha512_core`, `sha512_reg` | Direct SHA512 smoke. | High |
| `smoke_test_sha512_restore` | `SHA512` | `sha512_ctrl`, `sha512`, `sha512_core`, `sha512_reg` | SHA512 restore/context flow. | High |
| `smoke_test_sha_accel` | `SHA512_ACC`, `SOC_IFC` | `sha512_acc_top`, `sha512_acc_csr`, `sha512_core`, `soc_ifc_top` | SoC IFC SHA512 accelerator path. | High |
| `smoke_test_sram_ecc` | `MBOX`, `SOC_IFC` | `mbox`, `mbox_csr`, `soc_ifc_reg` | Mailbox SRAM ECC/error-count path; not the crypto `ECC` block despite the name. | Medium |
| `smoke_test_strap` | `SOC_IFC` | `soc_ifc_top`, `soc_ifc_reg` | Strap/configuration register behavior; no standalone strap RTL module found. | Medium |
| `smoke_test_trng` | `CSRNG/TRNG` | `csrng`, `entropy_src` | TRNG flow through CSRNG and entropy source registers. | High |
| `smoke_test_veer` | `VeeR/JTAG` | `el2_veer_wrapper`, `el2_veer`, `el2_dbg` | VeeR core smoke. | High |
| `smoke_test_wdt` | `WDT`, `SOC_IFC` | `wdt`, `soc_ifc_reg`, `soc_ifc_top` | Watchdog timer path. | High |
| `smoke_test_wdt_rst` | `WDT`, `SOC_IFC` | `wdt`, `soc_ifc_reg`, `soc_ifc_top` | Watchdog reset scenario. | High |
| `smoke_test_zeroize_crypto` | `HMAC`, `KV` | `hmac_ctrl`, `hmac`, `hmac_reg`, `kv` | Crypto zeroization path observed through HMAC/KV controls. | Medium |

## Ambiguities And Limits

- The mapping is not embedded directly in the smoke YAML files. It is inferred from test name, source includes/register macros, and the repo's RTL compile configuration.
- `KV` in a test name often means "this crypto block uses the key vault", not a pure key-vault-only test. Examples include ECC, HMAC, DOE, AES, MLDSA, and MLKEM KV flows.
- `MLDSA` and `MLKEM` map through the Adams Bridge RTL under `submodules/adams-bridge`, especially `abr_top`; the repo does not expose them as simple `src/mldsa/rtl` or `src/mlkem/rtl` top modules.
- `smoke_test_sram_ecc` maps to mailbox/SOC_IFC SRAM ECC status behavior, not the crypto ECC block.
- Scenario tests such as reset, RAS, strap, HEK, clock-gating, and zeroization intentionally exercise top-level control paths; those rows are marked `Medium` when there is no single standalone RTL block.
