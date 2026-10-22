* ============================================================================
* cmirror_1aN_tb.sp - Validacion Post-Layout Automatizada para Cmirror 1:2, 1:4, 1:8
* Simulador objetivo: ngspice
* ============================================================================

* ---------------- 1) Archivos del usuario -----------------------------------
.include ../../../../pdk/tech/models/CM05_models.lib
.include ../layout/Cmirror_1aN_pex.spice      $ Netlist extraido

* ---------------- 2) Fuentes y Estimulaciones -------------------------------
.param VDDV   = 5.0
.param IREFV  = 100u                         $ Corriente de prueba nominal

Vcom   COM   0 DC 0
Iref   0    P1 DC {IREFV}

* Fuentes independientes de polarizacion para cada salida analogica
Vout_2 P2_2  0 DC 2.5
Vout_4 P2_4  0 DC 2.5
Vout_8 P2_8  0 DC 2.5

* ---------------- 3) Instancia del DUT (Extraido) ---------------------------
X1 COM P2_8 P2_4 P2_2 P1 Cmirror_1aN_p

* ---------------- 4) Bloque de Control y Diagnostico ----------------------
.control
  set noaskquit

  * ------------- Parametros y Tolerancias (EDITABLES) --------------------
  let iref_nom    = 100e-6    $ Corriente nominal de prueba (100 uA)
  let max_err_pct = 5.0       $ Maximo error de copia permitido (%)
  let min_rout    = 20e3      $ Impedancia de salida Rout minima esperada (Ohms)
  let max_vmin    = 0.95      $ Compliance V_min maximo tolerable (V)

  * Factores de escala ideales
  let k_2 = 2.0
  let k_4 = 4.0
  let k_8 = 8.0

  echo ""
  echo "======================================================================"
  echo "      VALIDACION POST-LAYOUT: ESPEJO DE CORRIENTE (1:2, 1:4, 1:8)    "
  echo "======================================================================"

  * ------------- 1. PUNTO DE OPERACION DC Y RATIOS ------------------------
  op

  let ratio_2_val = -vout_2#branch / iref_nom
  let ratio_4_val = -vout_4#branch / iref_nom
  let ratio_8_val = -vout_8#branch / iref_nom

  let err_2_val = abs((ratio_2_val - k_2) / k_2) * 100
  let err_4_val = abs((ratio_4_val - k_4) / k_4) * 100
  let err_8_val = abs((ratio_8_val - k_8) / k_8) * 100

  * Guardar mediciones de la trama op1
  set r2 = $&ratio_2_val
  set r4 = $&ratio_4_val
  set r8 = $&ratio_8_val
  set e2 = $&err_2_val
  set e4 = $&err_4_val
  set e8 = $&err_8_val

  * ------------- 2. BARRIDO ROUT Y VMIN (RAMA 1:2) -----------------------
  dc Vout_2 0 5 0.01
  let io2 = -vout_2#branch
  let rout2 = 1 / (deriv(io2) + 1e-15)
  meas dc r_out_2_val FIND rout2 AT=2.5
  let i_t2 = iref_nom * k_2 * 0.995
  meas dc v_min_2_val WHEN io2=$&i_t2 RISE=1

  set ro2 = $&r_out_2_val
  set vm2 = $&v_min_2_val

  * ------------- 3. BARRIDO ROUT Y VMIN (RAMA 1:4) -----------------------
  dc Vout_4 0 5 0.01
  let io4 = -vout_4#branch
  let rout4 = 1 / (deriv(io4) + 1e-15)
  meas dc r_out_4_val FIND rout4 AT=2.5
  let i_t4 = iref_nom * k_4 * 0.995
  meas dc v_min_4_val WHEN io4=$&i_t4 RISE=1

  set ro4 = $&r_out_4_val
  set vm4 = $&v_min_4_val

  * ------------- 4. BARRIDO ROUT Y VMIN (RAMA 1:8) -----------------------
  dc Vout_8 0 5 0.01
  let io8 = -vout_8#branch
  let rout8 = 1 / (deriv(io8) + 1e-15)
  meas dc r_out_8_val FIND rout8 AT=2.5
  let i_t8 = iref_nom * k_8 * 0.995
  meas dc v_min_8_val WHEN io8=$&i_t8 RISE=1

  set ro8 = $&r_out_8_val
  set vm8 = $&v_min_8_val

  * ------------- REPORTE DE RESULTADOS Y DIAGNOSTICO ----------------------
  echo ""
  echo "---------------- DETALLE DE MEDICIONES POR RAMA ----------------------"
  echo " [Rama 1:2] Ratio: $r2 | Error: $e2 % | Rout: $ro2 Ohms | Vmin: $vm2 V"
  echo " [Rama 1:4] Ratio: $r4 | Error: $e4 % | Rout: $ro4 Ohms | Vmin: $vm4 V"
  echo " [Rama 1:8] Ratio: $r8 | Error: $e8 % | Rout: $ro8 Ohms | Vmin: $vm8 V"
  echo "----------------------------------------------------------------------"

  let pasa = 1

  * Evaluacion de Errores de Copia
  if $e2 > max_err_pct
    let pasa = 0
    echo " [FALLA] Error de copia fuera de norma en Rama 1:2"
  end
  if $e4 > max_err_pct
    let pasa = 0
    echo " [FALLA] Error de copia fuera de norma en Rama 1:4"
  end
  if $e8 > max_err_pct
    let pasa = 0
    echo " [FALLA] Error de copia fuera de norma en Rama 1:8"
  end

  * Evaluacion de Impedancia de Salida (Rout)
  if $ro2 < min_rout
    let pasa = 0
    echo " [FALLA] Rout insuficiente en Rama 1:2"
  end
  if $ro4 < min_rout
    let pasa = 0
    echo " [FALLA] Rout insuficiente en Rama 1:4"
  end
  if $ro8 < min_rout
    let pasa = 0
    echo " [FALLA] Rout insuficiente en Rama 1:8"
  end

  echo ""
  if pasa = 1
    echo " >>> VEREDICTO FINAL: ESPEJO MULTI-SALIDA COMPATIBLE (PASSED) <<<"
  else
    echo " >>> VEREDICTO FINAL: FALLA EN LAS ESPECIFICACIONES (FAILED) <<<"
  end
  echo "======================================================================"

.endc

.end