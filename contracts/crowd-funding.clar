;; crowd-funding
;; this contract manages campaigns

;; constants
(define-constant contract-owner tx-sender)
(define-constant create-campaign-fee u2000000)

(define-constant campaign-id-should-be-a-positive-integer (err u100))
(define-constant campaign-id-already-used (err u101))
(define-constant only-contract-owner-can-approve (err u102))
(define-constant campaign-not-found (err u103))
(define-constant only-campaign-owner-can-withdraw (err u104))
(define-constant invalid-balance (err u105))
(define-constant donation-should-be-a-positive-interger (err u105))

;; data maps and vars
(define-map campaigns { id: uint } { approved: bool, balance: uint, owner: principal, name: (string-ascii 50), description: (string-ascii 256), logo: (string-ascii 256)})

;; private functions
(define-private (get-owner (id uint)) 
  (begin
    (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
    (ok (get owner (map-get? campaigns {id: id})))
  )
)

;; public functions
(define-read-only (is-id-available (id uint)) 
  (begin
    (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
    (ok (is-none (map-get? campaigns {id: id})))
  )
)

(define-public (create-campaign (id uint) (name (string-ascii 50)) (description (string-ascii 256)) (logo (string-ascii 256))) 
  (begin
    (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
    (asserts! (is-eq (is-id-available id) (ok true)) campaign-id-already-used)
    (try! (stx-transfer? create-campaign-fee tx-sender (as-contract tx-sender)))
    ;; #[allow(unchecked_data)]
    (map-insert campaigns {id: id} {name: name, balance: u0, description: description, logo: logo, approved: false, owner: tx-sender})
    (ok id)
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
        (owner (unwrap! (get owner (map-get? campaigns {id: id})) invalid-balance))
        (balance (unwrap! (get balance (map-get? campaigns {id: id})) invalid-balance))
        (contract-address (as-contract tx-sender))
      )
      (asserts! (> id u0) campaign-id-should-be-a-positive-integer)
      (asserts! (is-eq owner tx-sender) only-campaign-owner-can-withdraw)
      (try! (as-contract (stx-transfer? balance contract-address owner)))
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
