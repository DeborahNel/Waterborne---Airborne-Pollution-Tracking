(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-sensor-exists (err u104))
(define-constant err-sensor-inactive (err u105))
(define-constant err-insufficient-stake (err u106))

(define-fungible-token compliance-token)

(define-data-var next-sensor-id uint u1)
(define-data-var penalty-rate uint u1000)
(define-data-var min-stake-amount uint u10000)

(define-map sensors
    { sensor-id: uint }
    {
        owner: principal,
        location: (string-ascii 100),
        sensor-type: (string-ascii 50),
        is-active: bool,
        stake-amount: uint,
        violation-count: uint,
        last-reading-time: uint
    }
)

(define-map pollution-readings
    { sensor-id: uint, timestamp: uint }
    {
        water-ph: uint,
        water-dissolved-oxygen: uint,
        air-pm25: uint,
        air-pm10: uint,
        air-co2: uint,
        temperature: uint,
        humidity: uint
    }
)

(define-map compliance-thresholds
    { pollution-type: (string-ascii 20) }
    { max-safe-level: uint }
)

(define-map sensor-operators
    { operator: principal }
    { authorized: bool, sensor-count: uint }
)

(define-map daily-violations
    { sensor-id: uint, date: uint }
    { violation-count: uint, total-penalty: uint }
)

(define-read-only (get-sensor (sensor-id uint))
    (map-get? sensors { sensor-id: sensor-id })
)

(define-read-only (get-pollution-reading (sensor-id uint) (timestamp uint))
    (map-get? pollution-readings { sensor-id: sensor-id, timestamp: timestamp })
)

(define-read-only (get-compliance-threshold (pollution-type (string-ascii 20)))
    (map-get? compliance-thresholds { pollution-type: pollution-type })
)

(define-read-only (get-sensor-operator (operator principal))
    (map-get? sensor-operators { operator: operator })
)

(define-read-only (get-daily-violations (sensor-id uint) (date uint))
    (map-get? daily-violations { sensor-id: sensor-id, date: date })
)

(define-read-only (is-authorized-operator (operator principal))
    (match (map-get? sensor-operators { operator: operator })
        some-operator (get authorized some-operator)
        false
    )
)

(define-read-only (get-penalty-rate)
    (var-get penalty-rate)
)

(define-read-only (get-min-stake-amount)
    (var-get min-stake-amount)
)

(define-public (initialize-thresholds)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set compliance-thresholds { pollution-type: "water-ph-min" } { max-safe-level: u650 })
        (map-set compliance-thresholds { pollution-type: "water-ph-max" } { max-safe-level: u850 })
        (map-set compliance-thresholds { pollution-type: "water-do" } { max-safe-level: u500 })
        (map-set compliance-thresholds { pollution-type: "air-pm25" } { max-safe-level: u3500 })
        (map-set compliance-thresholds { pollution-type: "air-pm10" } { max-safe-level: u5000 })
        (map-set compliance-thresholds { pollution-type: "air-co2" } { max-safe-level: u40000 })
        (ok true)
    )
)

(define-public (authorize-operator (operator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set sensor-operators { operator: operator } { authorized: true, sensor-count: u0 })
        (ok true)
    )
)

(define-public (revoke-operator (operator principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set sensor-operators { operator: operator } { authorized: false, sensor-count: u0 })
        (ok true)
    )
)

(define-public (register-sensor (location (string-ascii 100)) (sensor-type (string-ascii 50)))
    (let
        (
            (sensor-id (var-get next-sensor-id))
            (stake-amount (var-get min-stake-amount))
        )
        (asserts! (is-authorized-operator tx-sender) err-unauthorized)
        (asserts! (>= (stx-get-balance tx-sender) stake-amount) err-insufficient-stake)
        
        (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
        
        (map-set sensors
            { sensor-id: sensor-id }
            {
                owner: tx-sender,
                location: location,
                sensor-type: sensor-type,
                is-active: true,
                stake-amount: stake-amount,
                violation-count: u0,
                last-reading-time: u0
            }
        )
        
        (match (map-get? sensor-operators { operator: tx-sender })
            some-operator (map-set sensor-operators 
                { operator: tx-sender } 
                { authorized: true, sensor-count: (+ (get sensor-count some-operator) u1) })
            (map-set sensor-operators { operator: tx-sender } { authorized: true, sensor-count: u1 })
        )
        
        (var-set next-sensor-id (+ sensor-id u1))
        (ok sensor-id)
    )
)

(define-public (deactivate-sensor (sensor-id uint))
    (let
        (
            (sensor-data (unwrap! (map-get? sensors { sensor-id: sensor-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get owner sensor-data)) err-unauthorized)
        (asserts! (get is-active sensor-data) err-sensor-inactive)
        
        (map-set sensors
            { sensor-id: sensor-id }
            (merge sensor-data { is-active: false })
        )
        
        (try! (as-contract (stx-transfer? (get stake-amount sensor-data) tx-sender (get owner sensor-data))))
        (ok true)
    )
)

(define-public (submit-pollution-reading 
    (sensor-id uint)
    (water-ph uint)
    (water-dissolved-oxygen uint)
    (air-pm25 uint)
    (air-pm10 uint)
    (air-co2 uint)
    (temperature uint)
    (humidity uint)
)
    (let
        (
            (sensor-data (unwrap! (map-get? sensors { sensor-id: sensor-id }) err-not-found))
            (current-time stacks-block-height)
            (violations (calculate-violations water-ph water-dissolved-oxygen air-pm25 air-pm10 air-co2))
        )
        (asserts! (is-eq tx-sender (get owner sensor-data)) err-unauthorized)
        (asserts! (get is-active sensor-data) err-sensor-inactive)
        
        (map-set pollution-readings
            { sensor-id: sensor-id, timestamp: current-time }
            {
                water-ph: water-ph,
                water-dissolved-oxygen: water-dissolved-oxygen,
                air-pm25: air-pm25,
                air-pm10: air-pm10,
                air-co2: air-co2,
                temperature: temperature,
                humidity: humidity
            }
        )
        
        (map-set sensors
            { sensor-id: sensor-id }
            (merge sensor-data { 
                last-reading-time: current-time,
                violation-count: (+ (get violation-count sensor-data) violations)
            })
        )
        
        (if (> violations u0)
            (try! (apply-penalties sensor-id violations))
            true
        )
        
        (ok current-time)
    )
)

(define-private (calculate-violations (water-ph uint) (water-dissolved-oxygen uint) (air-pm25 uint) (air-pm10 uint) (air-co2 uint))
    (let
        (
            (ph-min-threshold (default-to u650 (get max-safe-level (map-get? compliance-thresholds { pollution-type: "water-ph-min" }))))
            (ph-max-threshold (default-to u850 (get max-safe-level (map-get? compliance-thresholds { pollution-type: "water-ph-max" }))))
            (do-threshold (default-to u500 (get max-safe-level (map-get? compliance-thresholds { pollution-type: "water-do" }))))
            (pm25-threshold (default-to u3500 (get max-safe-level (map-get? compliance-thresholds { pollution-type: "air-pm25" }))))
            (pm10-threshold (default-to u5000 (get max-safe-level (map-get? compliance-thresholds { pollution-type: "air-pm10" }))))
            (co2-threshold (default-to u40000 (get max-safe-level (map-get? compliance-thresholds { pollution-type: "air-co2" }))))
        )
        (+
            (if (or (< water-ph ph-min-threshold) (> water-ph ph-max-threshold)) u1 u0)
            (if (< water-dissolved-oxygen do-threshold) u1 u0)
            (if (> air-pm25 pm25-threshold) u1 u0)
            (if (> air-pm10 pm10-threshold) u1 u0)
            (if (> air-co2 co2-threshold) u1 u0)
        )
    )
)

(define-private (apply-penalties (sensor-id uint) (violation-count uint))
    (let
        (
            (penalty-amount (* violation-count (var-get penalty-rate)))
            (today (/ stacks-block-height u144))
            (current-daily-violations (default-to { violation-count: u0, total-penalty: u0 } 
                (map-get? daily-violations { sensor-id: sensor-id, date: today })))
        )
        (try! (ft-mint? compliance-token penalty-amount tx-sender))
        
        (map-set daily-violations
            { sensor-id: sensor-id, date: today }
            {
                violation-count: (+ (get violation-count current-daily-violations) violation-count),
                total-penalty: (+ (get total-penalty current-daily-violations) penalty-amount)
            }
        )
        (ok true)
    )
)

(define-public (update-compliance-threshold (pollution-type (string-ascii 20)) (max-safe-level uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set compliance-thresholds { pollution-type: pollution-type } { max-safe-level: max-safe-level })
        (ok true)
    )
)

(define-public (update-penalty-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set penalty-rate new-rate)
        (ok true)
    )
)

(define-public (emergency-shutdown-sensor (sensor-id uint))
    (let
        (
            (sensor-data (unwrap! (map-get? sensors { sensor-id: sensor-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        
        (map-set sensors
            { sensor-id: sensor-id }
            (merge sensor-data { is-active: false })
        )
        (ok true)
    )
)

(define-read-only (get-sensor-violations (sensor-id uint) (start-date uint) (end-date uint))
    (let
        (
            (violations-list (list))
        )
        (ok violations-list)
    )
)

(define-read-only (calculate-environmental-score (sensor-id uint))
    (let
        (
            (sensor-data (unwrap! (map-get? sensors { sensor-id: sensor-id }) err-not-found))
            (violation-count (get violation-count sensor-data))
        )
        (ok (if (<= violation-count u5) 
                (- u100 (* violation-count u10))
                u50))
    )
)

(define-constant min-reward-score u80)
(define-constant reward-amount u500)
(define-public (claim-compliance-reward (sensor-id uint))
  (let
    (
      (sensor-data (unwrap! (map-get? sensors { sensor-id: sensor-id }) err-not-found))
      (score (unwrap! (calculate-environmental-score sensor-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner sensor-data)) err-unauthorized)
    (asserts! (>= score min-reward-score) err-invalid-input)
    (try! (ft-mint? compliance-token reward-amount tx-sender))
    (ok true)
  )
)
(define-public (update-sensor-info (sensor-id uint) (new-location (string-ascii 100)) (new-sensor-type (string-ascii 50)))
  (let
    ((sensor-data (unwrap! (map-get? sensors { sensor-id: sensor-id }) err-not-found)))
    (asserts! (is-eq tx-sender (get owner sensor-data)) err-unauthorized)
    (asserts! (get is-active sensor-data) err-sensor-inactive)
    (map-set sensors
      { sensor-id: sensor-id }
      (merge sensor-data { location: new-location, sensor-type: new-sensor-type })
    )
    (ok true)
  )
)
