;; crowd-funding
;; this contract manages campaigns

;; constants
(define-constant contract-owner tx-sender)

(define-constant campaign-id-is-not-last-used-id-plus-one (err u100))
(define-constant campaign-id-already-used (err u101))
(define-constant only-contract-owner-can-approve (err u102))
(define-constant campaign-not-found (err u103))
(define-constant only-campaign-owner-can-withdraw (err u104))
(define-constant invalid-balance (err u105))
(define-constant donation-should-be-a-positive-interger (err u105))
(define-constant invalid-last-used (err u106))
(define-constant campaign-id-should-be-a-positive-integer (err u107))
(define-constant only-contract-owner-can-withdraw-fees (err u108))
(define-constant only-contract-owner-can-update-fees (err u109))
(define-constant fee-should-be-a-positive-integer (err u110))

;; data maps and vars
(define-map campaigns { id: uint } { approved: bool, balance: uint, target: uint, owner: principal, name: (buff 50), description: (buff 256), logo: (buff 256)})
(define-data-var last-used-id uint u0)
(define-data-var accumulated-fees uint u0)
(define-data-var create-campaign-fee uint u2000000)
;; private functions

(define-private (get-owner (id uint)) 
  (begin
    (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
    (ok (get owner (map-get? campaigns {id: id})))
  )
)

;; public functions
(define-read-only (get-last-used-id) 
  (ok (var-get last-used-id))
)

(define-read-only (get-campaign (id uint)) 
    (map-get? campaigns {id: id}) 
)

(define-read-only (get-campaign-creation-fee) 
  (ok (var-get create-campaign-fee))
)

(define-read-only (get-accumulated-fees) 
  (ok (var-get accumulated-fees))
)


(define-public (create-campaign (id uint) (name (buff 50)) (description (buff 256)) (logo (buff 256)) (target uint)) 
  (begin
    (let 
      (
        (contract-address (as-contract tx-sender))
        (fee (var-get create-campaign-fee))
      )
    
      (asserts! (is-eq id (+ (unwrap! (get-last-used-id) invalid-last-used) u1)) campaign-id-is-not-last-used-id-plus-one)
      (try! (stx-transfer? fee tx-sender contract-address))
      ;; #[allow(unchecked_data)]
      (map-insert campaigns {id: id} {name: name, balance: u0, target: target, description: description, logo: logo, approved: false, owner: tx-sender})
      (var-set last-used-id (+ (var-get last-used-id) u1))
      (var-set accumulated-fees (+ (var-get accumulated-fees) fee))
      (ok id)
    )
  )
)

(define-public (set-approval (id uint) (state bool)) 
  (begin
    (let 
      (
        (campaign (unwrap! (map-get? campaigns {id: id}) campaign-not-found))
      )
      (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
      (asserts! (is-eq contract-owner tx-sender) only-contract-owner-can-approve)
      (map-set campaigns {id: id} (merge campaign {approved: state}))
      (ok true)
    )
  )
)

(define-public (withdraw (id uint)) 
  (begin
    (let 
      (
        (campaign (unwrap! (map-get? campaigns {id: id}) campaign-not-found))
        (owner (unwrap! (get owner (map-get? campaigns {id: id})) invalid-balance))
        (balance (unwrap! (get balance (map-get? campaigns {id: id})) invalid-balance))
        (contract-address (as-contract tx-sender))
      )
      (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
      (asserts! (is-eq owner tx-sender) only-campaign-owner-can-withdraw)
      (try! (as-contract (stx-transfer? balance contract-address owner)))
      (map-set campaigns {id: id} (merge campaign {balance: u0}))
      (ok true)
    )
  )
)

(define-public (donate (id uint) (amount uint)) 
  (begin
    (let 
      (
        (campaign (unwrap! (map-get? campaigns {id: id}) campaign-not-found))
        (prev-balance (unwrap! (get balance (map-get? campaigns {id: id})) invalid-balance))
        (new-balance (+ prev-balance amount))
      )
      (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
      (asserts! (> amount u0) donation-should-be-a-positive-interger)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set campaigns {id: id} (merge campaign {balance: new-balance}))
      (ok new-balance)
    )
  )
)

(define-public (withdraw-fees) 
  (begin
    (let 
      (
        (contract-address (as-contract tx-sender))
        (accumulated-fees-from-creations (var-get accumulated-fees))
      )
      (asserts! (is-eq tx-sender contract-owner) only-contract-owner-can-withdraw-fees)
      (try! (as-contract  (stx-transfer? accumulated-fees-from-creations contract-address contract-owner)))
      (ok true)
    ) 
  )
)

(define-public (update-campaign-creation-fee (new-fee uint)) 
  (begin
      (asserts! (is-eq tx-sender contract-owner) only-contract-owner-can-update-fees)
      (asserts! (> new-fee u0) fee-should-be-a-positive-integer)
      (var-set create-campaign-fee new-fee)
      (ok true)
  )
)
