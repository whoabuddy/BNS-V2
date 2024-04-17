;; title: BNS-V2
;; version: V-1
;; summary: Updated BNS contract, handles the creation of new namespaces and new names on each namespace
;; description:

;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;;;;;; traits ;;;;;
;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Import SIP-09 NFT trait 
(impl-trait .sip-09.nft-trait)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Import a custom commission trait for handling commissions for NFT marketplaces functions
(use-trait commission-trait .commission-trait.commission)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Token Definition ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Define the non-fungible token (NFT) called BNS-V2 with unique identifiers as unsigned integers
(define-non-fungible-token BNS-V2 uint)

;; To be removed
;; A non-fungible token (NFT) representing a specific name within a namespace.
(define-non-fungible-token names { name: (buff 48), namespace: (buff 20) })

;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Constants ;;;;;
;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Constants for the token name and symbol, providing identifiers for the NFTs
(define-constant token-name "BNS-V2")
(define-constant token-symbol "BNS-V2")

;; Time-to-live (TTL) constants for namespace preorders and name preorders, and the duration for name grace period.
;; The TTL for namespace preorders.
(define-constant NAMESPACE-PREORDER-CLAIMABILITY-TTL u144) 
;; The duration after revealing a namespace within which it must be launched.
(define-constant NAMESPACE-LAUNCHABILITY-TTL u52595) 
;; The TTL for name preorders.
(define-constant NAME-PREORDER-CLAIMABILITY-TTL u144) 
;; The grace period duration for name renewals post-expiration.
(define-constant NAME-GRACE-PERIOD-DURATION u5000) 

;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
;; Price tables ;;
;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;

;; Defines the price tiers for namespaces based on their lengths.
(define-constant NAMESPACE-PRICE-TIERS (list
    u640000000000
    u64000000000 u64000000000 
    u6400000000 u6400000000 u6400000000 u6400000000 
    u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000 u640000000)
)

;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;
;;;; Errors ;;;;
;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;

(define-constant ERR-UNWRAP (err u101))
(define-constant ERR-NOT-AUTHORIZED (err u102))
(define-constant ERR-NOT-LISTED (err u103))
(define-constant ERR-WRONG-COMMISSION (err u104))
(define-constant ERR-LISTED (err u105))
(define-constant ERR-ALREADY-PRIMARY-NAME (err u106))
(define-constant ERR-NO-NAME (err u107))
(define-constant ERR-NAME-LOCKED (err u108))
(define-constant ERR-NAMESPACE-PREORDER-ALREADY-EXISTS (err u109))
(define-constant ERR-NAMESPACE-HASH-MALFORMED (err u110))
(define-constant ERR-NAMESPACE-STX-BURNT-INSUFFICIENT (err u111))
(define-constant ERR-INSUFFICIENT-FUNDS (err u112))
(define-constant ERR-NAMESPACE-PREORDER-NOT-FOUND (err u113))
(define-constant ERR-NAMESPACE-CHARSET-INVALID (err u114))
(define-constant ERR-NAMESPACE-ALREADY-EXISTS (err u115))
(define-constant ERR-NAMESPACE-PREORDER-CLAIMABILITY-EXPIRED (err u116))
(define-constant ERR-NAMESPACE-NOT-FOUND (err u117))
(define-constant ERR-NAMESPACE-OPERATION-UNAUTHORIZED (err u118))
(define-constant ERR-NAMESPACE-ALREADY-LAUNCHED (err u119))
(define-constant ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED (err u200))
(define-constant ERR-NAMESPACE-NOT-LAUNCHED (err u201))
(define-constant ERR-NAME-OPERATION-UNAUTHORIZED (err u202))
(define-constant ERR-NAME-NOT-AVAILABLE (err u203))
(define-constant ERR-NAME-NOT-FOUND (err u204))
(define-constant ERR-NAMESPACE-PREORDER-EXPIRED (err u205))
(define-constant ERR-NAMESPACE-UNAVAILABLE (err u206))
(define-constant ERR-NAMESPACE-PRICE-FUNCTION-INVALID (err u207))
(define-constant ERR-NAMESPACE-BLANK (err u208))
(define-constant ERR-NAME-PREORDER-NOT-FOUND (err u209))
(define-constant ERR-NAME-PREORDER-EXPIRED (err u210))
(define-constant ERR-NAME-PREORDER-FUNDS-INSUFFICIENT (err u211))
(define-constant ERR-NAME-UNAVAILABLE (err u212))
(define-constant ERR-NAME-STX-BURNT-INSUFFICIENT (err u213))
(define-constant ERR-NAME-EXPIRED (err u214))
(define-constant ERR-NAME-GRACE-PERIOD (err u215))
(define-constant ERR-NAME-BLANK (err u216))
(define-constant ERR-NAME-ALREADY-CLAIMED (err u217))
(define-constant ERR-NAME-CLAIMABILITY-EXPIRED (err u218))
(define-constant ERR-NAME-REVOKED (err u219))
(define-constant ERR-NAME-TRANSFER-FAILED (err u220))
(define-constant ERR-NAME-PREORDER-ALREADY-EXISTS (err u221))
(define-constant ERR-NAME-HASH-MALFORMED (err u222))
(define-constant ERR-NAME-PREORDERED-BEFORE-NAMESPACE-LAUNCH (err u223))
(define-constant ERR-NAME-NOT-RESOLVABLE (err u224))
(define-constant ERR-NAME-COULD-NOT-BE-MINTED (err u225))
(define-constant ERR-NAME-COULD-NOT-BE-TRANSFERED (err u226))
(define-constant ERR-NAME-CHARSET-INVALID (err u227))
(define-constant ERR-PRINCIPAL-ALREADY-ASSOCIATED (err u228))
(define-constant ERR-PANIC (err u229))
(define-constant ERR-NAMESPACE-HAS-MANAGER (err u230))
(define-constant ERR-OVERFLOW (err u231))

;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Variables ;;;;;
;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Counter to keep track of the last minted NFT ID, ensuring unique identifiers
(define-data-var bns-index uint u0)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Variable to store the token URI, allowing for metadata association with the NFT
(define-data-var token-uri (string-ascii 246) "")

;; Variable helper to remove an NFT from the list of owned NFTs by a user
(define-data-var uint-helper-to-remove uint u0)

;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;
;;;;;; Maps ;;;;;
;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;

;; Rule 1-1 -> 1 principal, 1 name

;; Maps a principal to the name they own, enforcing a one-to-one relationship between principals and names.
(define-map owner-name principal { name: (buff 48), namespace: (buff 20) })

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Map to track market listings, associating NFT IDs with price and commission details
(define-map market uint {price: uint, commission: principal})

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; This map tracks the primary name chosen by a user who owns multiple BNS names.
;; It maps a user's principal to the ID of their primary name.
(define-map primary-name principal uint)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Tracks all the BNS names owned by a user. Each user is mapped to a list of name IDs.
;; This allows for easy enumeration of all names owned by a particular user.
(define-map bns-ids-by-principal principal (list 1000 uint))


;;;;;;;;;;;;;
;; Updated ;;
;;;;;;;;;;;;;
;; Contains detailed properties of names, including registration and importation times, revocation status, and zonefile hash.
(define-map name-properties
    { name: (buff 48), namespace: (buff 20) }
    { 
        registered-at: (optional uint),
        imported-at: (optional uint),
        revoked-at: (optional uint),
        zonefile-hash: (optional (buff 20)),
        locked: bool, 
        renewal-height: uint,
        price: uint,
        owner: principal,
    }
)

;;;;;;;;;
;; New ;;
;;;;;;;;;
(define-map index-to-name uint 
    {
        name: (buff 48), namespace: (buff 20)
    } 
)

;;;;;;;;;
;; New ;;
;;;;;;;;;
(define-map name-to-index 
    {
        name: (buff 48), namespace: (buff 20)
    } 
    uint
)

;;;;;;;;;;;;;
;; Updated ;;
;;;;;;;;;;;;;
;; Stores properties of namespaces, including their import principals, reveal and launch times, and pricing functions.
(define-map namespaces (buff 20)
    { 
        namespace-manager: (optional principal),
        namespace-import: principal,
        revealed-at: uint,
        launched-at: (optional uint),
        lifetime: uint,
        can-update-price-function: bool,
        price-function: 
            {
                buckets: (list 16 uint),
                base: uint, 
                coeff: uint, 
                nonalpha-discount: uint, 
                no-vowel-discount: uint
            }
    }
)

;; Records namespace preorder transactions with their creation times, claim status, and STX burned.
(define-map namespace-preorders
    { hashed-salted-namespace: (buff 20), buyer: principal }
    { created-at: uint, claimed: bool, stx-burned: uint }
)


;; Tracks preorders for names, including their creation times, claim status, and STX burned.
(define-map name-preorders
    { hashed-salted-fqn: (buff 20), buyer: principal }
    { created-at: uint, claimed: bool, stx-burned: uint }
)

;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;
;;;;;; Public ;;;;;
;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; @desc SIP-09 compliant function to transfer a token from one owner to another
;; @param id: the id of the nft being transferred, owner: the principal of the owner of the nft being transferred, recipient: the principal the nft is being transferred to
(define-public (transfer (id uint) (owner principal) (recipient principal))
    (let 
        (
            ;; Attempts to retrieve the name and namespace associated with the given NFT ID. If not found, it returns an error.
            (name-and-namespace (unwrap! (map-get? index-to-name id) ERR-NO-NAME))
            ;; Extracts the namespace part from the retrieved name-and-namespace tuple.
            (namespace (get namespace name-and-namespace))
            ;; Extracts the name part from the retrieved name-and-namespace tuple.
            (name (get name name-and-namespace))
            ;; Fetches properties of the identified namespace to confirm its existence and retrieve management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the manager of the namespace, if one is set.
            (namespace-manager (get namespace-manager namespace-props))
            ;; Gets the name-props
            (name-props (unwrap! (map-get? name-properties name-and-namespace) ERR-NO-NAME))
            ;; Gets the current owner of the name from the name-props
            (name-current-owner (get owner name-props))
            ;; Gets the currently owned NFTs by the owner
            (all-nfts-owned-by-owner (default-to (list) (map-get? bns-ids-by-principal owner)))
            ;; Gets the currently owned NFTs by the recipient
            (all-nfts-owned-by-recipient (default-to (list) (map-get? bns-ids-by-principal recipient)))
            ;; Checks if the owner has a primary name
            (owner-primary-name (map-get? primary-name owner))
            ;; Checks if the recipient has a primary name
            (recipient-primary-name (map-get? primary-name recipient))
        )
        ;; Checks if the namespace is managed.
        (match namespace-manager 
            manager
            ;; If the namespace is managed, performs the transfer under the management's authorization.
            (begin                 
                ;; Asserts that the transaction caller is the namespace manager, hence authorized to handle the transfer.
                (asserts! (is-eq contract-caller (unwrap! namespace-manager ERR-UNWRAP)) ERR-NOT-AUTHORIZED)
            )
            (begin                 
                ;; Asserts that the transaction sender is the owner of the NFT to authorize the transfer.
                (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
            )  
        ) 
        ;; Ensures the NFT is not currently listed in the market, which would block transfers.
        (asserts! (is-none (map-get? market id)) ERR-LISTED)
        ;; Set the helper variable to remove the id being transferred from the list of currently owned nfts by owner
        (var-set uint-helper-to-remove id)
        ;; Updates currently owned names of the owner by removing the id being transferred
        (map-set bns-ids-by-principal owner (filter is-not-removeable all-nfts-owned-by-owner))
        ;; Updates currently owned names of the recipient by adding the id being transferred
        (map-set bns-ids-by-principal recipient (unwrap! (as-max-len? (append all-nfts-owned-by-recipient id) u1000) ERR-OVERFLOW))
        ;; Updates the primary name of the owner if needed, in the case that the id being transferred is the primary name
        (if (is-eq (some id) owner-primary-name) 
            ;; If the id is the primary name, then set it to the index 0 of the filtered list of the owner
            (map-set primary-name owner (unwrap! (element-at? (filter is-not-removeable all-nfts-owned-by-owner) u0) ERR-UNWRAP)) 
            ;; If it is not equal then do nothing
            false
        )
        ;; Updates the primary name of the receiver if needed, if the receiver doesn't have a name assign it as primary
        (match recipient-primary-name
            name-match
            ;; If there is a primary name then do nothing
            false
            ;; If no primary name then assign this as the primary name
            (map-set primary-name recipient id)
        )
        ;; Updates the name-props map with the new information, everything stays the same, we only change the zonefile to none for a clean slate and the owner
        (map-set name-properties name-and-namespace (merge name-props {zonefile-hash: none, owner: recipient}))
        ;; Executes the NFT transfer from owner to recipient if all conditions are met.
        (nft-transfer? BNS-V2 id owner recipient)
    )
)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; @desc Function to list an NFT for sale
;; @param id: the ID of the NFT in question, price: the price being listed, comm-trait: a principal that conforms to the commission-trait
(define-public (list-in-ustx (id uint) (price uint) (comm-trait <commission-trait>))
    (let
        (
            ;; Creates a listing record with price and commission details
            (listing {price: price, commission: (contract-of comm-trait)})
        )
        ;; Asserts that the caller is the owner of the NFT before listing it
        (asserts! (is-eq (some tx-sender) (unwrap! (get-owner id) ERR-UNWRAP)) ERR-NOT-AUTHORIZED)
        ;; Updates the market map with the new listing details
        (map-set market id listing)
        ;; Prints listing details
        (ok (print (merge listing {a: "list-in-ustx", id: id})))
    )
)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; @desc Function to remove an NFT listing from the market
;; @param id: the ID of the NFT in question, price: the price being listed, comm-trait: a principal that conforms to the commission-trait
(define-public (unlist-in-ustx (id uint))
    (begin
        ;; Asserts that the caller is the owner of the NFT before unlisting it
        (asserts! (is-eq (some tx-sender) (unwrap! (get-owner id) ERR-UNWRAP)) ERR-NOT-AUTHORIZED)
        ;; Deletes the listing from the market map
        (map-delete market id)
        ;; Prints unlisting details
        (ok (print {a: "unlist-in-stx", id: id}))
    )
)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; @desc Function to buy an NFT listed for sale, transferring ownership and handling commission
;; @param id: the ID of the NFT in question, comm-trait: a principal that conforms to the commission-trait for royalty split
(define-public (buy-in-ustx (id uint) (comm-trait <commission-trait>))
    (let
        (
            ;; Retrieves current owner and listing details
            (owner (unwrap! (unwrap! (get-owner id) ERR-UNWRAP) ERR-UNWRAP))
            (listing (unwrap! (map-get? market id) ERR-NOT-LISTED))
            (price (get price listing))
        )
        ;; Verifies the commission details match the listing
        (asserts! (is-eq (contract-of comm-trait) (get commission listing)) ERR-WRONG-COMMISSION)
        ;; Transfers STX from buyer to seller
        (try! (stx-transfer? price tx-sender owner))
        ;; Calls the commission contract to handle commission payment
        (try! (contract-call? comm-trait pay id price))
        ;; Transfers the NFT to the buyer
        (try! (transfer id owner tx-sender))
        ;; Removes the listing from the market map
        (map-delete market id)
        ;; Prints purchase details
        (ok (print {a: "buy-in-ustx", id: id}))
    )
)

;; Sets the primary name for the caller to a specific BNS name they own.
(define-public (set-primary-name (primary-name-id uint))
    (let 
        (
            ;; Retrieves the owner of the specified name ID
            (owner (unwrap! (nft-get-owner? BNS-V2 primary-name-id) ERR-UNWRAP))
            ;; Retrieves the current primary name for the caller, to check if an update is necessary.
            (current-primary-name (unwrap! (map-get? primary-name tx-sender) ERR-UNWRAP))
            ;; Retrieves the name and namespace from the uint/index
            (name-and-namespace (unwrap! (map-get? index-to-name primary-name-id) ERR-NO-NAME))
            ;; Retrieves the current locked status of the name
            (is-locked (unwrap! (get locked (map-get? name-properties name-and-namespace)) ERR-UNWRAP))
        ) 
        ;; Verifies that the caller (`tx-sender`) is indeed the owner of the name they wish to set as primary.
        (asserts! (is-eq owner tx-sender) ERR-NOT-AUTHORIZED)
        ;; Ensures the new primary name is different from the current one to avoid redundant updates.
        (asserts! (not (is-eq primary-name-id current-primary-name)) ERR-ALREADY-PRIMARY-NAME)
        ;; Asserts that the name is not locked
        (asserts! (is-eq false is-locked) ERR-NAME-LOCKED)
        ;; Updates the mapping of the caller's principal to the new primary name ID.
        (map-set primary-name tx-sender primary-name-id)
        ;; Returns 'true' upon successful execution of the function.
        (ok true)
    )
)

;; Defines a public function to burn an NFT, identified by its unique ID, under managed namespace authority.
(define-public (mng-burn (id uint)) 
    (let 
        (
            ;; Retrieves the name and namespace associated with the given NFT ID. If not found, returns an error.
            (name-and-namespace (unwrap! (map-get? index-to-name id) ERR-NAME-NOT-FOUND))

            ;; Extracts the namespace part from the retrieved name-and-namespace tuple.
            (namespace (get namespace name-and-namespace))

            ;; Fetches existing properties of the namespace to confirm its existence and retrieve management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))

            ;; Retrieves the current manager of the namespace from the namespace properties.
            (current-namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-UNWRAP))

            ;; Retrieves the current owner of the NFT, necessary to authorize the burn operation.
            (current-name-owner (unwrap! (nft-get-owner? BNS-V2 id) ERR-UNWRAP))
        ) 
        ;; Ensures that the function caller is the current namespace manager, providing the authority to perform the burn.
        (asserts! (is-eq contract-caller current-namespace-manager) ERR-NOT-AUTHORIZED)

        ;; Executes the burn operation for the specified NFT, effectively removing it from circulation.
        (ok (nft-burn? BNS-V2 id current-name-owner))
    )
)

;; Defines a public function for registering a new BNS name within a specified namespace.
(define-public (mng-register (name (buff 48)) (namespace (buff 20)) (send-to principal) (price uint) (zonefile (buff 20)))
    (let 
        (
            ;; Retrieves existing properties of the namespace to confirm its existence and management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            
            ;; Extracts the current manager of the namespace to verify the authority of the caller.
            (current-namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-UNWRAP))
            
            ;; Calculates the ID for the new name to be minted, incrementing the last used ID.
            (id-to-be-minted (+ (var-get bns-index) u1))
            
            ;; Retrieves a list of all names currently owned by the recipient. Defaults to an empty list if none are found.
            (all-users-names-owned (default-to (list) (map-get? bns-ids-by-principal send-to)))
        ) 
        ;; Verifies that the caller of the function is the current namespace manager to authorize the registration.
        (asserts! (is-eq contract-caller current-namespace-manager) ERR-NOT-AUTHORIZED)

        ;; Updates the list of all names owned by the recipient to include the new name ID.
        (map-set bns-ids-by-principal send-to (unwrap! (as-max-len? (append all-users-names-owned id-to-be-minted) u1000) ERR-UNWRAP))

        ;; Conditionally sets the newly minted name as the primary name if the recipient does not already have one.
        (match (map-get? primary-name send-to) 
            receiver
            false
            (map-set primary-name send-to id-to-be-minted)
        )

        ;; Sets properties for the newly registered name including registration time, price, owner, and associated zonefile hash.
        (map-set name-properties
            {
                name: name, namespace: namespace
            } 
            {
                registered-at: (some block-height),
                imported-at: none,
                revoked-at: none,
                zonefile-hash: (some zonefile),
                locked: false,
                renewal-height: (+ (get lifetime namespace-props) block-height),
                price: price,
                owner: send-to,
            }
        )

        ;; Links the newly minted ID to the name and namespace combination for reverse lookup.
        (map-set index-to-name id-to-be-minted {name: name, namespace: namespace})

        ;; Links the name and namespace combination to the newly minted ID for forward lookup.
        (map-set name-to-index {name: name, namespace: namespace} id-to-be-minted)

        ;; Mints the new BNS name as an NFT, assigned to the 'send-to' principal.
        (unwrap! (nft-mint? BNS-V2 id-to-be-minted send-to) ERR-UNWRAP)

        ;; Signals successful completion of the registration process.
        (ok true)
    )
)


;; This function transfers the management role of a specific namespace to a new principal.
(define-public (mng-manager-transfer (new-manager principal) (namespace (buff 20)))
    (let 
        (
            ;; Fetches existing properties of the namespace to verify its existence and current management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))

            ;; Extracts the current manager of the namespace from the retrieved properties.
            (current-namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-UNWRAP))
        ) 
        ;; Verifies that the caller of the function is the current namespace manager to authorize the management transfer.
        (asserts! (is-eq contract-caller current-namespace-manager) ERR-NOT-AUTHORIZED)

        ;; If the checks pass, updates the namespace entry with the new manager's principal.
        ;; Retains other properties such as the launched time and the lifetime of names.
        (ok 
            (map-set namespaces namespace 
                {
                    ;; Updates the namespace-manager field to the new manager's principal.
                    namespace-manager: (some new-manager),
                    namespace-import: new-manager,
                    revealed-at: (get revealed-at namespace-props),
                    ;; Retains the existing launch time of the namespace.
                    launched-at: (get launched-at namespace-props),
                    ;; Retains the existing lifetime duration setting for names within the namespace.
                    lifetime: (get lifetime namespace-props),
                    can-update-price-function: (get can-update-price-function namespace-props),
                    price-function: (get price-function namespace-props)
                }
            )
        )
    )
)

;;;; NAMESPACES
;; NAMESPACE-PREORDER
;; This step registers the salted hash of the namespace with BNS nodes, and burns the requisite amount of cryptocurrency.
;; Additionally, this step proves to the BNS nodes that user has honored the BNS consensus rules by including a recent
;; consensus hash in the transaction.
;; Returns pre-order's expiration date (in blocks).

;; Public function `namespace-preorder` initiates the registration process for a namespace by sending a transaction with a salted hash of the namespace.
;; This transaction burns the registration fee as a commitment.
;; @params:
    ;; hashed-salted-namespace (buff 20): The hashed and salted namespace being preordered.
    ;; stx-to-burn (uint): The amount of STX tokens to be burned as part of the preorder process.
(define-public (namespace-preorder (hashed-salted-namespace (buff 20)) (stx-to-burn uint))
    (let 
        (
            ;; Check if there's an existing preorder for the same hashed-salted-namespace by the same buyer.
            (former-preorder (map-get? namespace-preorders { hashed-salted-namespace: hashed-salted-namespace, buyer: tx-sender }))
        )
        ;; Verify that any previous preorder by the same buyer has expired.
        (asserts! 
            (match former-preorder
                preorder 
                ;; TODO - Update error message
                ;; If a previous preorder exists, check that it has expired based on the NAMESPACE-PREORDER-CLAIMABILITY-TTL.
                (>= block-height (+ NAMESPACE-PREORDER-CLAIMABILITY-TTL (unwrap! (get created-at former-preorder) ERR-UNWRAP))) 

                ;; Proceed if no previous preorder exists.
                true 
            ) 
            ERR-NAMESPACE-PREORDER-ALREADY-EXISTS
        )

        ;; Validate that the hashed-salted-namespace is exactly 20 bytes long to conform to expected hash standards.
        (asserts! (is-eq (len hashed-salted-namespace) u20) ERR-NAMESPACE-HASH-MALFORMED)
        ;; Confirm that the STX amount to be burned is positive
        (asserts! (> stx-to-burn u0) ERR-NAMESPACE-STX-BURNT-INSUFFICIENT)
        ;; Execute the token burn operation, deducting the specified STX amount from the buyer's balance.
        (unwrap! (stx-burn? stx-to-burn tx-sender) ERR-INSUFFICIENT-FUNDS)
        ;; Record the preorder details in the `namespace-preorders` map, marking it as not yet claimed.
        (map-set namespace-preorders
            { hashed-salted-namespace: hashed-salted-namespace, buyer: tx-sender }
            { created-at: block-height, claimed: false, stx-burned: stx-to-burn }
        )
        ;; Return the block height at which the preorder claimability expires, based on the NAMESPACE-PREORDER-CLAIMABILITY-TTL.
        (ok (+ block-height NAMESPACE-PREORDER-CLAIMABILITY-TTL))
    )
)

;; NAMESPACE-REVEAL
;; This second step reveals the salt and the namespace ID (pairing it with its NAMESPACE-PREORDER). It reveals how long
;; names last in this namespace before they expire or must be renewed, and it sets a price function for the namespace
;; that determines how cheap or expensive names its will be.

;; Public function `namespace-reveal` completes the second step in the namespace registration process by revealing the details of the namespace to the blockchain.
;; It associates the revealed namespace with its corresponding preorder, establishes the namespace's pricing function, and sets its lifetime and ownership details.
;; @params:
    ;; namespace (buff 20): The namespace being revealed.
    ;; namespace-salt (buff 20): The salt used during the preorder to generate a unique hash.
    ;; p-func-base, p-func-coeff, p-func-b1 to p-func-b16: Parameters defining the price function for registering names within this namespace.
    ;; p-func-non-alpha-discount (uint): Discount applied to names with non-alphabetic characters.
    ;; p-func-no-vowel-discount (uint): Discount applied to names without vowels.
    ;; lifetime (uint): Duration that names within this namespace are valid before needing renewal.
    ;; namespace-import (principal): The principal authorized to import names into this namespace.
(define-public (namespace-reveal (namespace (buff 20)) (namespace-salt (buff 20)) (p-func-base uint) (p-func-coeff uint) (p-func-b1 uint) (p-func-b2 uint) (p-func-b3 uint) (p-func-b4 uint) (p-func-b5 uint) (p-func-b6 uint) (p-func-b7 uint) (p-func-b8 uint) (p-func-b9 uint) (p-func-b10 uint) (p-func-b11 uint) (p-func-b12 uint) (p-func-b13 uint) (p-func-b14 uint) (p-func-b15 uint) (p-func-b16 uint) (p-func-non-alpha-discount uint) (p-func-no-vowel-discount uint) (lifetime uint) (namespace-import principal) (namespace-manager (optional principal)))
    ;; The salt and namespace must hash to a preorder entry in the `namespace-preorders` table.
    ;; The sender must match the principal in the preorder entry (implied)
    (let 
        (
            ;; Generate the hashed, salted namespace identifier to match with its preorder.
            (hashed-salted-namespace (hash160 (concat namespace namespace-salt)))
            ;; Define the price function based on the provided parameters.
            (price-function  
                {
                    buckets: (list p-func-b1 p-func-b2 p-func-b3 p-func-b4 p-func-b5 p-func-b6 p-func-b7 p-func-b8 p-func-b9 p-func-b10 p-func-b11 p-func-b12 p-func-b13 p-func-b14 p-func-b15 p-func-b16),
                    base: p-func-base,
                    coeff: p-func-coeff,
                    nonalpha-discount: p-func-non-alpha-discount,
                    no-vowel-discount: p-func-no-vowel-discount
                }
            )
            ;; Retrieve the preorder record to ensure it exists and is valid for the revealing namespace.
            (preorder (unwrap! (map-get? namespace-preorders { hashed-salted-namespace: hashed-salted-namespace, buyer: tx-sender }) ERR-NAMESPACE-PREORDER-NOT-FOUND))
            ;; Calculate the namespace's registration price for validation. Using the price tiers in the NAMESPACE-PRICE-TIERS
            (namespace-price (try! (get-namespace-price namespace)))
        )
        ;; Ensure the namespace consists of valid characters only.
        (asserts! (not (has-invalid-chars namespace)) ERR-NAMESPACE-CHARSET-INVALID)
        ;; Check that the namespace is available for reveal (not already existing or expired).
        (asserts! (is-namespace-available namespace) ERR-NAMESPACE-ALREADY-EXISTS)
        ;; Verify the burned amount during preorder meets or exceeds the namespace's registration price.
        (asserts! (>= (get stx-burned preorder) namespace-price) ERR-NAMESPACE-STX-BURNT-INSUFFICIENT)
        ;; Confirm the reveal action is performed within the allowed timeframe from the preorder.
        (asserts! (< block-height (+ (get created-at preorder) NAMESPACE-PREORDER-CLAIMABILITY-TTL)) ERR-NAMESPACE-PREORDER-CLAIMABILITY-EXPIRED)
        ;; Mark the preorder as claimed to prevent reuse.
        (map-set namespace-preorders
            { hashed-salted-namespace: hashed-salted-namespace, buyer: tx-sender }
            { created-at: (get created-at preorder), claimed: true, stx-burned: (get stx-burned preorder) }
        )
        ;; Register the namespace as revealed with its pricing function, lifetime, and import principal details.
        (map-set namespaces namespace
            {
                ;; New
                ;; Added manager here
                namespace-manager: namespace-manager,
                namespace-import: namespace-import,
                revealed-at: block-height,
                launched-at: none,
                lifetime: lifetime,
                can-update-price-function: true,
                price-function: price-function 
            }
        )
        ;; Confirm successful reveal of the namespace
        (ok true)
    )
)

;; NAMESPACE-READY
;; The final step of the process launches the namespace and makes the namespace available to the public. Once a namespace
;; is launched, anyone can register a name in it if they pay the appropriate amount of cryptocurrency.

;; Public function `namespace-ready` marks a namespace as launched and available for public name registrations.
;; This is the final step in the namespace creation process, opening up the namespace for anyone to register names in it.
;; @params:
    ;; namespace (buff 20): The namespace to be launched and made available for public registrations.
(define-public (namespace-ready (namespace (buff 20)))
    (let 
        (
            ;; Retrieve the properties of the namespace to ensure it exists and to check its current state.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
        )
        ;; Ensure the transaction sender is the namespace's designated import principal, confirming their authority to launch it.
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-NAMESPACE-OPERATION-UNAUTHORIZED)
        ;; Verify the namespace has not already been launched to prevent re-launching.
        (asserts! (is-none (get launched-at namespace-props)) ERR-NAMESPACE-ALREADY-LAUNCHED)
        ;; Confirm that the action is taken within the permissible time frame since the namespace was revealed.
        (asserts! (< block-height (+ (get revealed-at namespace-props) NAMESPACE-LAUNCHABILITY-TTL)) ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED)      
        (let 
            (
                ;; Update the namespace properties to include the launch timestamp, effectively marking it as "launched".
                (namespace-props-updated (merge namespace-props { launched-at: (some block-height) }))
            )
            ;; Update the `namespaces` map with the newly launched status of the namespace.
            (map-set namespaces namespace namespace-props-updated)
            ;; Emit an event to indicate the namespace is now ready and launched.
            (print { namespace: namespace, status: "ready", properties: namespace-props-updated })
            ;; Confirm the successful launch of the namespace.
            (ok true)
        )
    )
)

;; We can get rid of this, since namespace managers can do that on their own contract
;; NAME-IMPORT
;; Once a namespace is revealed, the user has the option to populate it with a set of names. Each imported name is given
;; both an owner and some off-chain state. This step is optional; Namespace creators are not required to import names.

;; Public function `name-import` allows the insertion of names into a namespace that has been revealed but not yet launched.
;; This facilitates pre-populating the namespace with specific names, assigning owners and zone file hashes to them.
;; @params:
    ;; namespace (buff 20): The namespace into which the name is being imported.
    ;; name (buff 48): The name being imported into the namespace.
    ;; beneficiary (principal): The principal who will own the imported name.
    ;; zonefile-hash (buff 20): The hash of the zone file associated with the imported name.
(define-public (name-import (namespace (buff 20)) (name (buff 48)) (beneficiary principal) (zonefile-hash (buff 20)) (price uint))
    (let 
        (
            ;; Fetch properties of the specified namespace to ensure it exists and to check its current state.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Fetch the latest index to mint
            (current-mint (+ (var-get bns-index) u1))
            ;; Fetch the primary name of the beneficiary
            (beneficiary-primary-name (map-get? primary-name beneficiary))
            ;; Fetch names owned by the beneficiary
            (all-users-names-owned (default-to (list) (map-get? bns-ids-by-principal beneficiary)))
        )
        ;; Verify that the name contains only valid characters to ensure compliance with naming conventions.
        (asserts! (not (has-invalid-chars name)) ERR-NAME-CHARSET-INVALID)
        ;; Ensure the transaction sender is the namespace's designated import principal, confirming their authority to import names.
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-NAMESPACE-OPERATION-UNAUTHORIZED)
        ;; Check that the namespace has not been launched yet, as names can only be imported to namespaces that are revealed but not launched.
        (asserts! (is-none (get launched-at namespace-props)) ERR-NAMESPACE-ALREADY-LAUNCHED)
        ;; Confirm that the import is occurring within the allowed timeframe since the namespace was revealed.
        (asserts! (< block-height (+ (get revealed-at namespace-props) NAMESPACE-LAUNCHABILITY-TTL)) ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED)
        ;; Check if beneficiary has primary-name
        (match beneficiary-primary-name
            primary
            ;; if it does then do nothing
            false
            ;; If not, then set this as primary name
            (map-set primary-name beneficiary current-mint)
        )
        ;; Add the name into the all-users-name map
        (map-set bns-ids-by-principal beneficiary (unwrap! (as-max-len? (append all-users-names-owned current-mint) u1000) ERR-OVERFLOW))
        ;; Set the name properties
        (map-set name-properties {name: name, namespace: namespace}
            {
                registered-at: none,
                imported-at: (some block-height),
                revoked-at: none,
                zonefile-hash: (some zonefile-hash),
                locked: false,
                renewal-height: (+ (get lifetime namespace-props) block-height),
                price: price,
                owner: beneficiary,
            }
        )
        ;; Set the map index-to-name
        (map-set index-to-name current-mint {name: name, namespace: namespace})
        ;; Set the map name-to-index
        (map-set name-to-index {name: name, namespace: namespace} current-mint)
         ;; Mint the name to the beneficiary
        (unwrap! (nft-mint? BNS-V2 current-mint beneficiary) ERR-NAME-COULD-NOT-BE-MINTED)
        ;; ;; Update the name's properties in the `name-properties` map, setting its zone file hash and marking it as imported.
        ;; (update-zonefile-and-props namespace name none (some block-height) none zonefile-hash "name-import")
        ;; Confirm successful import of the name.
        (ok true)
    )
)

;; NAMESPACE-UPDATE-FUNCTION-PRICE
;; Public function `namespace-update-function-price` updates the pricing function for a specific namespace.
;; This allows changing how the cost of registering names within the namespace is calculated.
;; @params:
    ;; namespace (buff 20): The namespace for which the price function is being updated.
    ;; p-func-base (uint): The base price used in the pricing function.
    ;; p-func-coeff (uint): The coefficient used in the pricing function.
    ;; p-func-b1 to p-func-b16 (uint): The bucket-specific multipliers for the pricing function.
    ;; p-func-non-alpha-discount (uint): The discount applied for non-alphabetic characters.
    ;; p-func-no-vowel-discount (uint): The discount applied when no vowels are present.
(define-public (namespace-update-function-price (namespace (buff 20)) (p-func-base uint) (p-func-coeff uint) (p-func-b1 uint) (p-func-b2 uint) (p-func-b3 uint) (p-func-b4 uint) (p-func-b5 uint) (p-func-b6 uint) (p-func-b7 uint) (p-func-b8 uint) (p-func-b9 uint) (p-func-b10 uint) (p-func-b11 uint) (p-func-b12 uint) (p-func-b13 uint) (p-func-b14 uint) (p-func-b15 uint) (p-func-b16 uint) (p-func-non-alpha-discount uint) (p-func-no-vowel-discount uint))
    (let 
        (
            ;; Retrieve the current properties of the namespace to ensure it exists and fetch its current price function.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Construct the new price function based on the provided parameters.
            (price-function 
                {
                    buckets: (list p-func-b1 p-func-b2 p-func-b3 p-func-b4 p-func-b5 p-func-b6 p-func-b7 p-func-b8 p-func-b9 p-func-b10 p-func-b11 p-func-b12 p-func-b13 p-func-b14 p-func-b15 p-func-b16),
                    base: p-func-base,
                    coeff: p-func-coeff,
                    nonalpha-discount: p-func-non-alpha-discount,
                    no-vowel-discount: p-func-no-vowel-discount
                }
            )
        )
        ;; Ensure that the transaction sender is the namespace's designated import principal.
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-NAMESPACE-OPERATION-UNAUTHORIZED)
        ;; Verify that the namespace's price function is still allowed to be updated.
        (asserts! (get can-update-price-function namespace-props) ERR-NAMESPACE-OPERATION-UNAUTHORIZED)
        ;; Update the namespace's record in the `namespaces` map with the new price function.
        (map-set namespaces namespace (merge namespace-props { price-function: price-function }))
        ;; Confirm the successful update of the price function.
        (ok true)
    )
)

;; NAMESPACE-REVOKE-PRICE-EDITION
;; Public function `namespace-revoke-function-price-edition` disables the ability to update the price function for a given namespace.
;; This is a finalizing action ensuring that the price for registering names within the namespace cannot be altered once set.
;; @params:
    ;; namespace (buff 20): The target namespace for which the price function update capability is being revoked.
(define-public (namespace-revoke-function-price-edition (namespace (buff 20)))
    (let 
        (
            ;; Retrieve the properties of the specified namespace to verify its existence and fetch its current settings.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
        )
        ;; Ensure that the transaction sender is the same as the namespace's designated import principal.
        ;; This check ensures that only the owner or controller of the namespace can revoke the price function update capability.
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-NAMESPACE-OPERATION-UNAUTHORIZED)
        ;; Update the namespace properties in the `namespaces` map, setting `can-update-price-function` to false.
        ;; This action effectively locks the price function, preventing any future changes.
        (map-set namespaces namespace 
            (merge namespace-props { can-update-price-function: false })
        )
        ;; Return a success confirmation, indicating the price function update capability has been successfully revoked.
        (ok true)
    )
)

;; NAME-PREORDER
;; This is the first transaction to be sent. It tells all BNS nodes the salted hash of the BNS name,
;; and it burns the registration fee.

;; Do we need to add the namespace here? 

;; Public function `name-preorder` initiates the registration process for a BNS name by sending a transaction with a salted hash of the name.
;; This transaction burns the registration fee as a demonstration of commitment and to prevent spamming.
;; @params:
    ;; hashed-salted-fqn (buff 20): The hashed and salted fully qualified name (FQN) being preordered.
    ;; stx-to-burn (uint): The amount of STX tokens to be burned as part of the preorder process.
(define-public (name-preorder (hashed-salted-fqn (buff 20)) (stx-to-burn uint))
    (let 
        (
            ;; Check if there is an existing preorder for the same hashed-salted-fqn by the same buyer.
            (former-preorder (map-get? name-preorders { hashed-salted-fqn: hashed-salted-fqn, buyer: tx-sender }))
        )
        ;; Verify that any previous preorder by the same buyer has expired.
        (asserts! 
            (match former-preorder
                preorder
                ;; If a previous preorder exists, check that it has expired based on the NAME-PREORDER-CLAIMABILITY-TTL.
                (>= block-height (+ NAME-PREORDER-CLAIMABILITY-TTL (unwrap-panic (get created-at former-preorder))))
                ;; If no previous preorder exists, proceed.
                true
            )
            ;; If a previous preorder is still valid, throw an error indicating a duplicate preorder.
            ERR-NAME-PREORDER-ALREADY-EXISTS
        )
        ;; Validate that the STX amount to be burned is greater than 0 to ensure a valid transaction.
        (asserts! (> stx-to-burn u0) ERR-NAMESPACE-STX-BURNT-INSUFFICIENT)  
        ;; Ensure that the hashed and salted FQN is exactly 20 bytes long to match the expected hash format.
        (asserts! (is-eq (len hashed-salted-fqn) u20) ERR-NAME-HASH-MALFORMED)
        ;; Confirm that the STX amount to be burned is a positive value.
        ;; This is not necessary since we are asserting exactly the same before
        (asserts! (> stx-to-burn u0) ERR-NAME-STX-BURNT-INSUFFICIENT)
        ;; Execute the token burn operation, removing the specified amount of STX from the buyer's balance.
        (unwrap! (stx-burn? stx-to-burn tx-sender) ERR-INSUFFICIENT-FUNDS)
        ;; Record the preorder details in the `name-preorders` map, marking it as not yet claimed.
        (map-set name-preorders
            { hashed-salted-fqn: hashed-salted-fqn, buyer: tx-sender }
            { created-at: block-height, stx-burned: stx-to-burn, claimed: false }
        )
        ;; Return the block height at which the preorder claimability period will expire, based on NAME-PREORDER-CLAIMABILITY-TTL.
        (ok (+ block-height NAME-PREORDER-CLAIMABILITY-TTL))
    )
)

;; NAME-REGISTRATION
;; This is the second transaction to be sent. It reveals the salt and the name to all BNS nodes,
;; and assigns the name an initial public key hash and zone file hash

;; Public function `name-register` for finalizing the registration of a name within a namespace.
;; This function reveals the salted hash of the name, linking it with its preorder, and sets up initial properties for the name.
;; @params:
    ;; namespace (buff 20): The namespace in which the name is being registered.
    ;; name (buff 48): The actual name being registered.
    ;; salt (buff 20): The salt used during the preorder to generate the hashed, salted fully-qualified name (FQN).
    ;; zonefile-hash (buff 20): The hash of the zone file associated with the name.
(define-public (name-register (namespace (buff 20)) (name (buff 48)) (salt (buff 20)) (zonefile-hash (buff 20)))
    (let 
        (
            ;; Generate the hashed, salted FQN from the provided name, namespace, and salt.
            (hashed-salted-fqn (hash160 (concat (concat (concat name 0x2e) namespace) salt)))
            ;; Retrieve the properties of the namespace to ensure it exists and is valid for registration.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; New
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
            ;; Retrieve the preorder information using the hashed, salted FQN to verify the preorder exists and belongs to the tx sender.
            (preorder (unwrap! (map-get? name-preorders { hashed-salted-fqn: hashed-salted-fqn, buyer: tx-sender }) ERR-NAME-PREORDER-NOT-FOUND))
            ;; Added this
            ;; Retreive the name owner if any
            (name-index (map-get? name-to-index {name: name, namespace: namespace}))
        )
        ;; New
        ;; Assert that the namespace doesn't have a manager, if it does then only the manager can register names
        (asserts! (is-none namespace-manager) ERR-NAMESPACE-HAS-MANAGER)
        ;; Changed this
        ;; Verify the name is eligible for registration within the given namespace.
        (asserts! (is-none name-index) ERR-NAME-UNAVAILABLE)
        ;; Ensure the preorder was made after the namespace was launched to be valid.
        (asserts! (> (get created-at preorder) (unwrap-panic (get launched-at namespace-props))) ERR-NAME-PREORDERED-BEFORE-NAMESPACE-LAUNCH)
        ;; Check that the preorder has not already been claimed to prevent duplicate registrations.
        (asserts! (is-eq (get claimed preorder) false) ERR-NAME-ALREADY-CLAIMED)
        ;; Ensure the registration is completed within the claimability period after the preorder.
        (asserts! (< block-height (+ (get created-at preorder) NAME-PREORDER-CLAIMABILITY-TTL)) ERR-NAME-CLAIMABILITY-EXPIRED)
        ;; Confirm the amount of STX burned with the preorder meets or exceeds the cost of registering the name.
        (asserts! (>= (get stx-burned preorder) (compute-name-price name (get price-function namespace-props))) ERR-NAME-STX-BURNT-INSUFFICIENT)
        ;; Mint or transfer the name to the tx sender, effectively finalizing its registration or updating ownership if already existing.

        ;; ;; Update the name's properties with the new zone file hash and registration metadata.
        ;; (update-zonefile-and-props namespace name (some block-height) none none zonefile-hash "name-register")
        ;; Confirm successful registration of the name.
        (ok true)
    )
)

;; NAME-UPDATE
;; A NAME-UPDATE transaction changes the name's zone file hash. You would send one of these transactions 
;; if you wanted to change the name's zone file contents. 
;; For example, you would do this if you want to deploy your own Gaia hub and want other people to read from it.

;; Public function `name-update` for changing the zone file hash associated with a name.
;; This operation is typically used to update the zone file contents of a name, such as when deploying a new Gaia hub.
;; @params:
    ;; namespace (buff 20): The namespace of the name whose zone file hash is being updated.
    ;; name (buff 48): The name whose zone file hash is being updated.
    ;; zonefile-hash (buff 20): The new zone file hash to be associated with the name.
(define-public (name-update (namespace (buff 20)) (name (buff 48))  (zonefile-hash (buff 20)))
    (let 
        (
            ;; Check preconditions to ensure the operation is authorized, including that the caller is the current owner, and the name is in a valid state for updates (not expired, not in grace period, and not revoked).
            (data (try! (check-name-ops-preconditions namespace name)))
            ;; Retrieve the properties of the namespace to ensure it exists and is valid for registration.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; New
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
        )
        ;; New
        ;; Assert that the namespace doesn't have a manager, if it does then only the manager can register names
        (asserts! (is-none namespace-manager) ERR-NAMESPACE-HAS-MANAGER)
        ;; ;; Execute the update of the zone file hash for the name. This involves updating the name's properties in the `name-properties` map with the new zone file hash. The operation type "name-update" is also specified for logging.
        ;; (update-zonefile-and-props namespace name (get registered-at (get name-props data)) (get imported-at (get name-props data)) none zonefile-hash "name-update")
        ;; Confirm successful completion of the zone file hash update.
        (ok true)
    )
)

;; NAME-REVOKE
;; A NAME-REVOKE transaction makes a name unresolvable. The BNS consensus rules stipulate that once a name 
;; is revoked, no one can change its public key hash or its zone file hash. 
;; The name's zone file hash is set to null to prevent it from resolving.
;; You should only do this if your private key is compromised, or if you want to render your name unusable for whatever reason.

;; Public function `name-revoke` for making a name unresolvable.
;; @params:
    ;; namespace (buff 20): The namespace of the name to be revoked.
    ;; name (buff 48): The actual name to be revoked.
(define-public (name-revoke (namespace (buff 20)) (name (buff 48)))
    (let 
        (
            ;; Check preconditions for name operations such as ownership and namespace launch status.
            (data (try! (check-name-ops-preconditions namespace name)))
            ;; Retrieve the properties of the namespace to ensure it exists and is valid for registration.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; New
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
        )
        ;; New
        ;; Assert that the namespace doesn't have a manager, if it does then only the manager can register names
        (asserts! (is-none namespace-manager) ERR-NAMESPACE-HAS-MANAGER)
        ;; ;; Update the name properties to revoke the name:
        ;;     ;; - The zone file hash is set to null (0x), effectively making the name unresolvable.
        ;;     ;; - The `update-zonefile-and-props` function is called with the current registered and imported timestamps, the current block height as the revoked timestamp, and a null zone file hash.
        ;;     ;; - The operation type "name-revoke" is passed to `update-zonefile-and-props` for logging.
        ;; (update-zonefile-and-props namespace name (get registered-at (get name-props data)) (get imported-at (get name-props data)) (some block-height) 0x "name-revoke")
        ;; Return a success response indicating the name has been successfully revoked.
        (ok true)
    )
)

;; NAME-RENEWAL
;; Depending in the namespace rules, a name can expire. For example, names in the .id namespace expire after 2 years. 
;; You need to send a NAME-RENEWAL every so often to keep your name.
;; You will pay the registration cost of your name to the namespace's designated burn address when you renew it.
;; When a name expires, it enters a month-long "grace period" (5000 blocks). 
;; It will stop resolving in the grace period, and all of the above operations will cease to be honored by the BNS consensus rules.
;; You may, however, send a NAME-RENEWAL during this grace period to preserve your name.
;; If your name is in a namespace where names do not expire, then you never need to use this transaction.

;; Public function `name-renewal` for renewing ownership of a name.
;; @params 
    ;; namespace (buff 20): The namespace of the name to be renewed.
    ;; name (buff 48): The actual name to be renewed.
    ;; stx-to-burn (uint): The amount of STX tokens to be burned for renewal.
    ;;;;;;;;;
;; New ;;
;;;;;;;;;-owner (optional principal): The new owner of the name, if changing ownership.
    ;; zonefile-hash (optional (buff 20)): The new zone file hash for the name, if updating.
(define-public (name-renewal (namespace (buff 20)) (name (buff 48)) (stx-to-burn uint) (new-owner (optional principal)) (zonefile-hash (optional (buff 20))))
    (let 
        (
            ;; Fetch the namespace properties from the `namespaces` map.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Get the current owner of the name from the `names` map.
            (owner (unwrap! (nft-get-owner? names { name: name, namespace: namespace }) ERR-NAME-NOT-FOUND))
            ;; Fetch the name properties from the `name-properties` map.
            (name-props (unwrap! (map-get? name-properties { name: name, namespace: namespace }) ERR-NAME-NOT-FOUND))
            ;; New
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
        )
        ;; New
        ;; Assert that the namespace doesn't have a manager, if it does then only the manager can register names
        (asserts! (is-none namespace-manager) ERR-NAMESPACE-HAS-MANAGER)
        ;; Asserts that the namespace has been launched.
        (asserts! (is-some (get launched-at namespace-props)) ERR-NAMESPACE-NOT-LAUNCHED)
        ;; Asserts that renewals are required for names in this namespace
        (asserts! (> (get lifetime namespace-props) u0) ERR-NAME-OPERATION-UNAUTHORIZED)
        ;; Asserts that the sender of the transaction matches the current owner of the name.
        (asserts! (is-eq owner tx-sender) ERR-NAME-OPERATION-UNAUTHORIZED)
        ;; Checks if the name's lease has expired and if it is currently within the grace period for renewal.
        (if (try! (is-name-lease-expired namespace name))
            (asserts! (is-eq (try! (is-name-in-grace-period namespace name)) true) ERR-NAME-EXPIRED)
            true
        )
        ;; Asserts that the amount of STX to be burned is at least equal to the renewal price of the name.
        (asserts! (>= stx-to-burn (compute-name-price name (get price-function namespace-props))) ERR-NAME-STX-BURNT-INSUFFICIENT)
        ;; Asserts that the name has not been revoked.
        (asserts! (is-none (get revoked-at name-props)) ERR-NAME-REVOKED)
        ;; Burns the STX provided
        (unwrap! (stx-burn? stx-to-burn tx-sender) ERR-UNWRAP)
        ;; Checks if a new owner is specified
        (match new-owner
            owner-new
            ;; If new owner, then checks if the new owner can receive the name.
            (try! (can-receive-name (unwrap-panic new-owner)))
            ;; If no new owner return true
            true    
        )
        ;; Checks if a new zone file hash is specified
        (match zonefile-hash
            z-hash
            (map-set name-properties
                { 
                    name: name, 
                    namespace: namespace 
                }
                { 
                    registered-at: (some block-height),
                    imported-at: none,
                    revoked-at: none,
                    zonefile-hash: zonefile-hash,
                    locked: (get locked name-props),
                    renewal-height: (+ (get lifetime namespace-props) block-height),
                    owner: (get owner name-props),
                    price: (get price name-props),
                }
            )
            ;; If no new zone file hash then keep existing hash
            (map-set name-properties
                { 
                    name: name, 
                    namespace: namespace 
                }
                { 
                    registered-at: (some block-height),
                    imported-at: none,
                    revoked-at: none,
                    zonefile-hash: (get zonefile-hash name-props),
                    locked: (get locked name-props),
                    renewal-height: (+ (get lifetime namespace-props) block-height),
                    owner: (get owner name-props),
                    price: (get price name-props),
                }
            )
            
            ;; ;; If new zone file hash, then update with new zone file hash
            ;; (update-zonefile-and-props namespace name (some block-height) none none (unwrap-panic zonefile-hash) "name-renewal")
        )
        ;; Successfully completes the renewal process.
        (ok true)
    )
)

;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;
;;;;; Read Only ;;;;
;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;

;; @desc SIP-09 compliant function to get the last minted token's ID
(define-read-only (get-last-token-id)
    ;; Returns the current value of bns-index variable, which tracks the last token ID
    (ok (var-get bns-index))
)

;; @desc SIP-09 compliant function to get token URI
(define-read-only (get-token-uri (id uint))
    ;; Returns a predefined set URI for the token metadata
    (ok (some (var-get token-uri)))
)

;; @desc SIP-09 compliant function to get the owner of a specific token by its ID
(define-read-only (get-owner (id uint))
    ;; Check and return the owner of the specified NFT
    (ok (nft-get-owner? BNS-V2 id))
)

;; This read-only function determines the availability of a specific BNS (Blockchain Name Service) name within a specified namespace.
(define-read-only (is-name-available (name (buff 48)) (namespace (buff 20)))
    (let 
        (
            ;; Attempts to retrieve properties of the specified namespace to ensure it exists.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))

            ;; Attempts to find an index for the name-namespace pair, which would indicate prior registration.
            (name-index (map-get? name-to-index {name: name, namespace: namespace}))

            ;; Tries to get the properties associated with the name within the namespace, if it's registered.
            (name-props (map-get? name-properties {name: name, namespace: namespace}))
        ) 
        ;; Returns the availability status based on whether name properties were found.
        (ok
            (if (is-none name-props)
                {
                    ;; If no properties are found, the name is considered available, and no renewal or price info is applicable.
                    available: true,
                    renews-at: none,
                    price: none
                }
                {
                    ;; If properties are found, the name is not available, and the function returns its renewal height and price.
                    available: false,
                    renews-at: (get renewal-height name-props),  ;; The block height at which the name needs to be renewed.
                    price: (get price name-props)  ;; The current registration price for the name.
                }
            )
        )
    )
)


;; Read-only function `get-namespace-price` calculates the registration price for a namespace based on its length.
;; @params:
    ;; namespace (buff 20): The namespace for which the price is being calculated.
(define-read-only (get-namespace-price (namespace (buff 20)))
    (let 
        (
            ;; Calculate the length of the namespace.
            (namespace-len (len namespace))
        )
        ;; Ensure the namespace is not blank, its length is greater than 0.
        (asserts! (> namespace-len u0) ERR-NAMESPACE-BLANK)
        ;; Retrieve the price for the namespace based on its length from the NAMESPACE-PRICE-TIERS list.
        ;; The price tier is determined by the minimum of 7 or the namespace length minus one.
        (ok (unwrap-panic (element-at NAMESPACE-PRICE-TIERS (min u7 (- namespace-len u1)))))
    )
)

;; Read-only function `get-name-price` calculates the registration price for a name within a specific namespace.
;; @params:
    ;; namespace (buff 20): The namespace within which the name's price is being calculated.
    ;; name (buff 48): The name for which the price is being calculated.
(define-read-only (get-name-price (namespace (buff 20)) (name (buff 48)))
    (let 
        (
            ;; Fetch properties of the specified namespace to access its price function.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
        )
        ;; Calculate and return the price for the specified name using the namespace's price function.
        (ok (compute-name-price name (get price-function namespace-props)))
    )
)

;; Read-only function `check-name-ops-preconditions` ensures that all necessary conditions are met for operations on a specific name.
;; @params:
    ;; namespace (buff 20): The namespace of the name being checked.
    ;; name (buff 48): The name being checked for operation preconditions.
(define-read-only (check-name-ops-preconditions (namespace (buff 20)) (name (buff 48)))
    (let 
        (
            ;; Retrieve the owner of the name from the `names` map, ensuring the name exists.
            (owner (unwrap! (nft-get-owner? names { name: name, namespace: namespace }) ERR-NAME-NOT-FOUND))
            ;; Fetch properties of the namespace, ensuring the namespace exists.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Fetch properties of the name, ensuring the name exists.
            (name-props (unwrap! (map-get? name-properties { name: name, namespace: namespace }) ERR-NAME-NOT-FOUND))
        ) 
        ;; Asserts the namespace has been launched.
        (asserts! (is-some (get launched-at namespace-props)) ERR-NAMESPACE-NOT-LAUNCHED)
        ;; Asserts the transaction sender is the current owner of the name.
        (asserts! (is-eq owner tx-sender) ERR-NAME-OPERATION-UNAUTHORIZED)
        ;; Asserts the name is not in its renewal grace period.
        (asserts! (is-eq (try! (is-name-in-grace-period namespace name)) false) ERR-NAME-GRACE-PERIOD)
        ;; Asserts the name lease has not expired.
        (asserts! (is-eq (try! (is-name-lease-expired namespace name)) false) ERR-NAME-EXPIRED)
        ;; Asserts the name has not been revoked.
        (asserts! (is-none (get revoked-at name-props)) ERR-NAME-REVOKED)
        ;; Returns a tuple containing the namespace properties, name properties, and the owner of the name if all checks pass.
        (ok { namespace-props: namespace-props, name-props: name-props, owner: owner })
    )
)

;; Read-only function `can-namespace-be-registered` checks if a namespace is available for registration.
;; @params:
    ;; namespace (buff 20): The namespace being checked for availability.
(define-read-only (can-namespace-be-registered (namespace (buff 20)))
    ;; Returns the result of `is-namespace-available` directly, indicating if the namespace can be registered.
    (ok (is-namespace-available namespace))
)

;; Read-only function `is-name-lease-expired` checks if the lease for a specific name has expired.
;; @params:
    ;; namespace (buff 20): The namespace of the name being checked.
    ;; name (buff 48): The name being checked for lease expiration.
(define-read-only (is-name-lease-expired (namespace (buff 20)) (name (buff 48)))
    (let 
        (
            ;; Fetch properties of the namespace, ensuring the namespace exists.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Fetch properties of the name, ensuring the name exists.
            (name-props (unwrap! (map-get? name-properties { name: name, namespace: namespace }) ERR-NAME-NOT-FOUND))
            ;; Determine the lease start date based on namespace launch and name properties.
            (lease-started-at (try! (name-lease-started-at? (get launched-at namespace-props) (get revealed-at namespace-props) name-props)))
            ;; Retrieve the lifetime of names within this namespace.
            (lifetime (get lifetime namespace-props))
        )
        ;; If the namespace's lifetime for names is set to 0 (indicating names do not expire)
        (if (is-eq lifetime u0)
            ;; Return false.
            (ok false)
            ;; Otherwise, check if the current block height is greater than the sum of the lease start and lifetime, indicating expiration.
            (ok (> block-height (+ lifetime lease-started-at)))
        )
    )
)

;; Read-only function `is-name-in-grace-period` checks if a specific name within a namespace is currently in its grace period.
;; @params:
    ;; namespace (buff 20): The namespace of the name being checked.
    ;; name (buff 48): The specific name being checked for grace period status.
(define-read-only (is-name-in-grace-period (namespace (buff 20)) (name (buff 48)))
    (let 
        (
            ;; Fetch properties of the specified namespace.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Fetch properties of the specific name.
            (name-props (unwrap! (map-get? name-properties { name: name, namespace: namespace }) ERR-NAME-NOT-FOUND))
            ;; Determine the start of the lease for the name based on its namespace's launch and the name's specific properties.
            (lease-started-at (try! (name-lease-started-at? (get launched-at namespace-props) (get revealed-at namespace-props) name-props)))
            ;; Retrieve the lifetime duration of names within this namespace.
            (lifetime (get lifetime namespace-props))
        )
        ;; If the namespace's lifetime for names is set to 0 (indicating names do not expire).
        (if (is-eq lifetime u0)
            ;; Return false as names cannot be in a grace period.
            (ok false)
            ;; Otherwise, check if the current block height falls within the grace period after the name's lease has expired.
            (ok (and 
                    (> block-height (+ lifetime lease-started-at)) 
                    (<= block-height (+ (+ lifetime lease-started-at) NAME-GRACE-PERIOD-DURATION))
                )
            )
        )
    )
)

;; Read-only function `can-receive-name` checks if a given principal is eligible to receive a new name.
;; @params:
    ;; owner (principal): The principal whose eligibility to receive a new name is being checked.
(define-read-only (can-receive-name (owner principal))
    (let 
        (
            ;; Attempt to fetch the name currently owned by the principal from the `owner-name` map.
            (current-owned-name (map-get? owner-name owner))
        )
        ;; Check if the principal currently does not own a name.
        (if (is-none current-owned-name)
            ;; If the principal does not own any name, they are eligible to receive one.
            (ok true)
            ;; If the principal already owns a name, further checks are required.
            (let 
                (
                    ;; Extract the namespace and name from the owned name's details.
                    (namespace (unwrap-panic (get namespace current-owned-name)))
                    (name (unwrap-panic (get name current-owned-name)))
                )
                ;; Check if the namespace of the currently owned name is available.
                (if (is-namespace-available namespace)
                    ;; If the namespace is available, the principal can receive a new name.
                    (ok true)
                    (begin
                        ;; Check if the lease for the currently owned name has expired.
                        (asserts! (not (try! (is-name-lease-expired namespace name))) (ok true))
                        (let 
                            (
                                ;; Fetch properties of the currently owned name.
                                (name-props (unwrap-panic (map-get? name-properties { name: name, namespace: namespace })))
                            )
                            ;; Check if the currently owned name has been revoked.
                            (asserts! (is-some (get revoked-at name-props)) (ok false))
                            ;; If the name has not been revoked, the principal can receive a new name.
                            (ok true)
                        )
                    )
                )
            )
        )
    )
)

;; Read-only function `get-namespace-properties` for retrieving properties of a specific namespace.
;; @params:
    ;; namespace (buff 20): The namespace whose properties are being queried.
(define-read-only (get-namespace-properties (namespace (buff 20)))
    (let 
        (
            ;; Fetch the properties of the specified namespace from the `namespaces` map.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
        )
        ;; Returns the namespace along with its associated properties.
        (ok { namespace: namespace, properties: namespace-props })
    )
)


;; Defines a read-only function to fetch the unique ID of a BNS name given its name and the namespace it belongs to.
(define-read-only (get-id-from-bns (name (buff 48)) (namespace (buff 20))) 
    ;; Attempts to retrieve the ID from the 'name-to-index' map using the provided name and namespace as the key.
    (map-get? name-to-index {name: name, namespace: namespace})
)

;; Fetcher for all BNS ids owned by a principal
(define-read-only (get-all-names-owned-by-principal (owner principal))
    (map-get? bns-ids-by-principal owner)
)


;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
;;;;; Private ;;;;
;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;


;; Returns the minimum of two uint values.
(define-private (min (a uint) (b uint))
    ;; If 'a' is less than or equal to 'b', return 'a', else return 'b'.
    (if (<= a b) a b)  
)

;; Returns the maximum of two uint values.
(define-private (max (a uint) (b uint))
    ;; If 'a' is greater than 'b', return 'a', else return 'b'.
    (if (> a b) a b)  
)

;; Retrieves an exponent value from a list of buckets based on the provided index.
(define-private (get-exp-at-index (buckets (list 16 uint)) (index uint))
    ;; Retrieves the element at the specified index.
    (unwrap-panic (element-at buckets index))  
)

;; Determines if a character is a digit (0-9).
(define-private (is-digit (char (buff 1)))
    (or 
        ;; Checks if the character is between '0' and '9' using hex values.
        (is-eq char 0x30) ;; 0
        (is-eq char 0x31) ;; 1
        (is-eq char 0x32) ;; 2
        (is-eq char 0x33) ;; 3
        (is-eq char 0x34) ;; 4
        (is-eq char 0x35) ;; 5
        (is-eq char 0x36) ;; 6
        (is-eq char 0x37) ;; 7
        (is-eq char 0x38) ;; 8
        (is-eq char 0x39) ;; 9
    )
) 

;; Checks if a character is a lowercase alphabetic character (a-z).
(define-private (is-lowercase-alpha (char (buff 1)))
    (or 
        ;; Checks for each lowercase letter using hex values.
        (is-eq char 0x61) ;; a
        (is-eq char 0x62) ;; b
        (is-eq char 0x63) ;; c
        (is-eq char 0x64) ;; d
        (is-eq char 0x65) ;; e
        (is-eq char 0x66) ;; f
        (is-eq char 0x67) ;; g
        (is-eq char 0x68) ;; h
        (is-eq char 0x69) ;; i
        (is-eq char 0x6a) ;; j
        (is-eq char 0x6b) ;; k
        (is-eq char 0x6c) ;; l
        (is-eq char 0x6d) ;; m
        (is-eq char 0x6e) ;; n
        (is-eq char 0x6f) ;; o
        (is-eq char 0x70) ;; p
        (is-eq char 0x71) ;; q
        (is-eq char 0x72) ;; r
        (is-eq char 0x73) ;; s
        (is-eq char 0x74) ;; t
        (is-eq char 0x75) ;; u
        (is-eq char 0x76) ;; v
        (is-eq char 0x77) ;; w
        (is-eq char 0x78) ;; x
        (is-eq char 0x79) ;; y
        (is-eq char 0x7a) ;; z
    )
) 

;; Determines if a character is a vowel (a, e, i, o, u, and y).
(define-private (is-vowel (char (buff 1)))
    (or 
        (is-eq char 0x61) ;; a
        (is-eq char 0x65) ;; e
        (is-eq char 0x69) ;; i
        (is-eq char 0x6f) ;; o
        (is-eq char 0x75) ;; u
        (is-eq char 0x79) ;; y
    )
)

;; Identifies if a character is a special character, specifically '-' or '_'.
(define-private (is-special-char (char (buff 1)))
    (or 
        (is-eq char 0x2d) ;; -
        (is-eq char 0x5f)) ;; _
) 

;; Determines if a character is valid within a name, based on allowed character sets.
(define-private (is-char-valid (char (buff 1)))
    (or (is-lowercase-alpha char) (is-digit char) (is-special-char char))
)

;; Checks if a character is non-alphabetic, either a digit or a special character.
(define-private (is-nonalpha (char (buff 1)))
    (or (is-digit char) (is-special-char char))
)

;; Evaluates if a name contains any vowel characters.
(define-private (has-vowels-chars (name (buff 48)))
    (> (len (filter is-vowel name)) u0)
)

;; Determines if a name contains non-alphabetic characters.
(define-private (has-nonalpha-chars (name (buff 48)))
    (> (len (filter is-nonalpha name)) u0)
)

;; Identifies if a name contains any characters that are not considered valid.
(define-private (has-invalid-chars (name (buff 48)))
    (< (len (filter is-char-valid name)) (len name))
)

;; Calculates the block height at which a name's lease started, considering if it was registered or imported.
(define-private (name-lease-started-at? (namespace-launched-at (optional uint)) (namespace-revealed-at uint) (name-props { registered-at: (optional uint), imported-at: (optional uint), revoked-at: (optional uint), zonefile-hash: (optional (buff 20)), locked: bool, renewal-height: uint, price: uint, owner: principal}))
    (let 
        (
            ;; Extract the registration and importation times from the name properties.
            (registered-at (get registered-at name-props))
            (imported-at (get imported-at name-props))
        )
        (if (is-none namespace-launched-at)
            ;; If the namespace has not been launched:
            (begin
                ;; Ensure the namespace has not expired by comparing the current block height with the namespace reveal time plus TTL.
                (asserts! (> (+ namespace-revealed-at NAMESPACE-LAUNCHABILITY-TTL) block-height) ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED) 
                ;; Return the block height at which the name was imported if the namespace is yet to launch.
                (ok (unwrap-panic imported-at))
            )
            ;; If the namespace has been launched:
            (begin
                ;; Confirm the namespace is launched by checking the launch timestamp is set.
                (asserts! (is-some namespace-launched-at) ERR-NAMESPACE-NOT-LAUNCHED)
                ;; Ensure the name has been either registered or imported, but not both.
                (asserts! (is-eq (xor 
                    (match registered-at res 1 0)
                    (match imported-at   res 1 0)) 1) 
                    ERR-PANIC
                )
                ;; Determine the lease start based on registration or importation:
                (if (is-some registered-at)
                    ;; If the name was registered, return the registration block height.
                    (ok (unwrap-panic registered-at))
                    ;; If the name was imported, check if it was between the namespace reveal and launch.
                    (if (and (>= (unwrap-panic imported-at) namespace-revealed-at) (<= (unwrap-panic imported-at) (unwrap-panic namespace-launched-at)))
                        ;; If imported correctly, return the namespace launch block height as the lease start.
                        (ok (unwrap-panic namespace-launched-at))
                        ;; If the importation timing does not match criteria, return 0.
                        (ok u0)
                    )
                )
            )
        )
    )
)

;; Private helper function `update-zonefile-and-props` updates the properties of a name, including its zone file hash.
;; It also emits an event to signal the update operation, useful for tracking and external integrations.
;; @params:
    ;; namespace (buff 20): The namespace of the name being updated.
    ;; name (buff 48): The name being updated.
    ;; registered-at (optional uint): The block height at which the name was registered. None if not updating this field.
    ;; imported-at (optional uint): The block height at which the name was imported. None if not updating this field.
    ;; revoked-at (optional uint): The block height at which the name was revoked. None if not updating this field.
    ;; zonefile-hash (buff 20): The new zone file hash for the name.
    ;; op (string-ascii 16): A string indicating the operation performed (e.g., "name-register", "name-import").
(define-private (update-zonefile-and-props (namespace (buff 20)) (name (buff 48)) (registered-at (optional uint)) (imported-at (optional uint)) (revoked-at (optional uint)) (zonefile-hash (buff 20)) (op (string-ascii 16)))
    (let 
        (
            ;; Retrieve the current index for attachments to keep track of this operation uniquely.
            (current-index (var-get bns-index))
            (name-props (unwrap! (map-get? name-properties {name: name, namespace: namespace}) ERR-UNWRAP))
        )
        ;; Log the operation as an event with relevant metadata, including the zone file hash, name, namespace, and operation type.
        (print 
            {
                attachment: 
                    {
                        hash: zonefile-hash,
                        bns-index: current-index,
                        metadata: 
                            {
                                name: name,
                                namespace: namespace,
                                tx-sender: tx-sender,
                                op: op
                            }
                    }
            }
        )
        ;; Increment the attachment index for future operations to maintain uniqueness.
        (var-set bns-index (+ u1 current-index))
        ;; Update the name's properties in the `name-properties` map with the new zone file hash and any other provided properties.
        (ok (map-set name-properties
            { name: name, namespace: namespace }
            { 
                registered-at: registered-at,
                imported-at: imported-at,
                revoked-at: revoked-at,
                zonefile-hash: (some zonefile-hash), 
                locked: (get locked name-props), 
                renewal-height: (get renewal-height name-props),
                price: (get price name-props),
                owner: (get owner name-props),
            }
        ))
    )
)

;; Private helper function `is-namespace-available` checks if a namespace is available for registration or other operations.
;; It considers if the namespace has been launched and whether it has expired.
;; @params:
    ;; namespace (buff 20): The namespace to check for availability.
(define-private (is-namespace-available (namespace (buff 20)))
    (match 
        ;; Attempt to fetch the properties of the namespace from the `namespaces` map.
        (map-get? namespaces namespace) 
        namespace-props
        (begin
            ;; Check if the namespace has been launched. If it has, it may not be available for certain operations.
            (if (is-some (get launched-at namespace-props)) 
                ;; If the namespace is launched, it's considered unavailable if it hasn't expired.
                false
                ;; Check if the namespace is expired by comparing the current block height to the reveal time plus the launchability TTL.
                (> block-height (+ (get revealed-at namespace-props) NAMESPACE-LAUNCHABILITY-TTL)))
        ) 
        ;; If the namespace doesn't exist in the map, it's considered available.
        true
    )
)

;; Private helper function `compute-name-price` calculates the registration price for a name based on its length and character composition.
;; It utilizes a configurable pricing function that can adjust prices based on the name's characteristics.
;; @params:
    ;; name (buff 48): The name for which the price is being calculated.
    ;; price-function (tuple): A tuple containing the parameters of the pricing function, including:
        ;; buckets (list 16 uint): A list defining price multipliers for different name lengths.
        ;; base (uint): The base price multiplier.
        ;; coeff (uint): A coefficient that adjusts the base price.
        ;; nonalpha-discount (uint): A discount applied to names containing non-alphabetic characters.
        ;; no-vowel-discount (uint): A discount applied to names lacking vowel characters.
(define-private (compute-name-price (name (buff 48)) (price-function {buckets: (list 16 uint), base: uint, coeff: uint, nonalpha-discount: uint, no-vowel-discount: uint}))
    (let 
        (
            ;; Determine the appropriate exponent based on the name's length, which corresponds to a specific bucket in the pricing function.
            (exponent (get-exp-at-index (get buckets price-function) (min u15 (- (len name) u1))))
            ;; Calculate the no-vowel discount. If the name has no vowels, apply the discount; otherwise, use 1 (no discount).
            (no-vowel-discount (if (not (has-vowels-chars name)) (get no-vowel-discount price-function) u1))
            ;; Calculate the non-alphabetic character discount. If the name contains non-alphabetic characters, apply the discount; otherwise, use 1.
            (nonalpha-discount (if (has-nonalpha-chars name) (get nonalpha-discount price-function) u1))
        )
        ;; Compute the final price by multiplying the base price adjusted by the coefficient and exponent, then dividing by the greater of the two discounts.
        ;; The result is further scaled by a factor of 10 to adjust for unit precision.
        (* (/ (* (get coeff price-function) (pow (get base price-function) exponent)) (max nonalpha-discount no-vowel-discount)) u10)
    )
)

;; @desc - Helper function for removing a specific NFT from the NFTs list
(define-private (is-not-removeable (nft uint))
  (not (is-eq nft (var-get uint-helper-to-remove)))
)