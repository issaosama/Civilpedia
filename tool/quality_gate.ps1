# Civilpedia V1-R09Q-A deterministic CI quality gate.
#
# Frozen authority: V1-R09Q-CONTRACT-v1 + ARCHITECT ADDENDUM A (CI ACTIVATION
# SEQUENCING). This script is the suite-list SSOT.
#
# Rules enforced here:
#   - one suite per process, strictly sequential (no parallel test processes);
#   - each suite runs as `flutter test --no-pub <single-suite>`;
#   - fail-fast on the first FAILED required suite with a non-zero exit code;
#   - every listed suite is REQUIRED: a missing file is a hard failure, never a
#     silent skip;
#   - no analyzer, no format, no build, no `pub get`, and no Supabase here.
#
# The A-stage list below intentionally excludes the two R09Q-B-owned frozen
# suites (`test/v1_r09q_migration_lint_test.dart`,
# `test/v1_r09q_security_matrix_test.dart`), which do not exist during R09Q-A
# and are activated by R09Q-B per Addendum A. That phase boundary is encoded
# here as a phase-scoped suite list, not as skip/try-catch suppression.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $root 'pubspec.yaml'))) {
  Write-Host 'ERROR: repository root could not be located.' -ForegroundColor Red
  exit 1
}

Push-Location $root
try {
  $flutter = Get-Command flutter -ErrorAction SilentlyContinue
  if ($null -eq $flutter) {
    Write-Host 'ERROR: flutter is not available on PATH.' -ForegroundColor Red
    exit 1
  }

  $suites = @(
    'test/v1_r09q_smoke_journeys_test.dart'
    'test/v1_r09_p2_g_integrated_gate_test.dart'
    'test/v1_r09_p2_shared_ux_test.dart'
    'test/remote_operation_policy_test.dart'
    'test/app_shell_test.dart'
    'test/v1_r09_c2_sign_out_recovery_test.dart'
    'test/v1_r09_c3_credential_exchange_quarantine_test.dart'
    'test/v1_r09_p2_c_authenticated_profile_read_foundation_test.dart'
    'test/v1_r08_auth_session_foundation_test.dart'
    'test/v1_r08_router_auth_test.dart'
    'test/auth_recovery_foundation_test.dart'
    'test/auth_provider_test.dart'
    'test/supabase_auth_gateway_test.dart'
    'test/v1_r03_business_ownership_management_test.dart'
    'test/v1_r06_profile_management_server_test.dart'
    'test/v1_r07_staff_operations_server_test.dart'
    'test/v1_r07_staff_gateway_production_test.dart'
  )

  $missing = @()
  foreach ($suite in $suites) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $suite))) {
      $missing += $suite
    }
  }
  if ($missing.Count -gt 0) {
    Write-Host 'ERROR: required A-stage suite files are missing:' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
  }

  $passed = 0
  $failed = 0
  $failedSuite = $null

  foreach ($suite in $suites) {
    Write-Host ''
    Write-Host "=== flutter test --no-pub $suite ===" -ForegroundColor Cyan
    & flutter test --no-pub $suite
    $code = $LASTEXITCODE
    if ($code -eq 0) {
      $passed++
      Write-Host "PASS  $suite" -ForegroundColor Green
    } else {
      $failed++
      $failedSuite = $suite
      Write-Host "FAIL  $suite (exit code $code)" -ForegroundColor Red
      break
    }
  }

  Write-Host ''
  Write-Host '=== Quality gate summary ==='
  Write-Host "Passed: $passed  Failed: $failed"
  if ($failed -gt 0) {
    Write-Host "First failed suite: $failedSuite" -ForegroundColor Red
    Write-Host 'Quality gate FAILED.' -ForegroundColor Red
    exit 1
  }
  Write-Host 'Quality gate PASSED.' -ForegroundColor Green
  exit 0
}
finally {
  Pop-Location
}