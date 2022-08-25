;; crowd-funding
;; this contract manages campaigns

;; constants
;;
(define-constant contract-owner tx-sender)

;; data maps and vars
;;
(define-map campaigns { id: uint } { approved: bool, balance: uint, owner: principal, name: (string-ascii 50), description: (string-ascii 256), logo: (string-ascii 256)})

;; private functions
;;

;; public functions
;;
