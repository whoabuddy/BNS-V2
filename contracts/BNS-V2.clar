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

;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Constants ;;;;;
;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;

;; Time-to-live (TTL) constants for namespace preorders and name preorders, and the duration for name grace period.
;; The TTL for namespace and names preorders. (1 day)
(define-constant PREORDER-CLAIMABILITY-TTL u144) 
;; The duration after revealing a namespace within which it must be launched. (1 year)
(define-constant NAMESPACE-LAUNCHABILITY-TTL u52595) 
;; The grace period duration for name renewals post-expiration. (34 days)
(define-constant NAME-GRACE-PERIOD-DURATION u5000) 
;; The length of the hash should match this
(define-constant HASH160LEN u20)

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
(define-constant ERR-PREORDER-ALREADY-EXISTS (err u108))
(define-constant ERR-HASH-MALFORMED (err u109))
(define-constant ERR-STX-BURNT-INSUFFICIENT (err u110))
(define-constant ERR-PREORDER-NOT-FOUND (err u111))
(define-constant ERR-CHARSET-INVALID (err u112))
(define-constant ERR-NAMESPACE-ALREADY-EXISTS (err u113))
(define-constant ERR-PREORDER-CLAIMABILITY-EXPIRED (err u114))
(define-constant ERR-NAMESPACE-NOT-FOUND (err u115))
(define-constant ERR-OPERATION-UNAUTHORIZED (err u116))
(define-constant ERR-NAMESPACE-ALREADY-LAUNCHED (err u117))
(define-constant ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED (err u118))
(define-constant ERR-NAMESPACE-NOT-LAUNCHED (err u119))
(define-constant ERR-NAME-NOT-AVAILABLE (err u120))
(define-constant ERR-NAMESPACE-BLANK (err u121))
(define-constant ERR-NAME-EXPIRED (err u122))
(define-constant ERR-NAME-GRACE-PERIOD (err u123))
(define-constant ERR-NAME-BLANK (err u124))
(define-constant ERR-NAME-REVOKED (err u125))
(define-constant ERR-NAME-PREORDER-ALREADY-EXISTS (err u127))
(define-constant ERR-NAME-PREORDERED-BEFORE-NAMESPACE-LAUNCH (err u128))
(define-constant ERR-NAMESPACE-HAS-MANAGER (err u129))
(define-constant ERR-OVERFLOW (err u130))
(define-constant ERR-NO-BNS-NAMES-OWNED (err u131))
(define-constant ERR-NO-NAMESPACE-MANAGER (err u132))
(define-constant ERR-OWNER-IS-THE-SAME (err u133))
(define-constant ERR-FAST-MINTED-BEFORE (err u134))
(define-constant ERR-PREORDERED-BEFORE (err u135))
(define-constant ERR-NAME-NOT-CLAIMABLE-YET (err u136))
(define-constant ERR-BURN-UPDATES-FAILED (err u137))
(define-constant ERR-IMPORTED-BEFORE (err u138))

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

;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;
;;;;;; Maps ;;;;;
;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Map to track market listings, associating NFT IDs with price and commission details
(define-map market uint {price: uint, commission: principal})

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Define a map to link NFT IDs to their respective names and namespaces.
(define-map index-to-name uint 
    {
        name: (buff 48), namespace: (buff 20)
    } 
)

;;;;;;;;;
;; New ;;
;;;;;;;;;
;; Define a map to link names and namespaces to their respective NFT IDs.
(define-map name-to-index 
    {
        name: (buff 48), namespace: (buff 20)
    } 
    uint
)

;;;;;;;;;;;;;
;; Updated ;;
;;;;;;;;;;;;;
;; Contains detailed properties of names, including registration and importation times, revocation status, and zonefile hash.
(define-map name-properties
    { name: (buff 48), namespace: (buff 20) }
    {
        registered-at: (optional uint),
        imported-at: (optional uint),
        ;; Updated this to be a boolean, since we do not need know when it was revoked, only if it is revoked
        revoked-at: bool,
        zonefile-hash: (optional (buff 20)),
        ;; The fqn used to make the earliest preorder at any given point
        fully-qualified-name: (optional (buff 20)),
        ;; Added this field in name-properties to know exactly who has the earliest preorder at any given point
        preordered-by: (optional principal),
        renewal-height: uint,
        stx-burn: uint,
        owner: principal,
    }
)

;;;;;;;;;;;;;
;; Updated ;;
;;;;;;;;;;;;;
;; Stores properties of namespaces, including their import principals, reveal and launch times, and pricing functions.
(define-map namespaces (buff 20)
    { 
        namespace-manager: (optional principal),
        manager-transferable: bool,
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
;; Removed the claimed field as it is not necessary
(define-map namespace-preorders
    { hashed-salted-namespace: (buff 20), buyer: principal }
    { created-at: uint, stx-burned: uint }
)

;; Tracks preorders for names, including their creation times, claim status, and STX burned.
;; Removed the claimed field as it is not necessary
(define-map name-preorders
    { hashed-salted-fqn: (buff 20), buyer: principal }
    { created-at: uint, stx-burned: uint}
)

;; Defines a map to keep track of the imported names by namespace, so when the namespace is launched we update the renewal time accordingly
(define-map imported-names (buff 20) (list 1000 uint))

;; This map tracks the primary name chosen by a user who owns multiple BNS names.
;; It maps a user's principal to the ID of their primary name.
(define-map primary-name principal uint)
;; Define maps for managing the linked list and name ownership
;; Maps principal to the last name ID in their list
(define-map owners-last-name principal uint) 
;; Maps name ID to the next name ID in the list
(define-map next-name-in-list uint uint) 
;; Maps name ID to the previous name ID in the list
(define-map previous-name-in-list uint uint) 
;; Maps name ID to the owner principal
(define-map bns-name-owner uint principal) 
;; Maps principal to the count of names they own
(define-map owner-bns-balance principal uint)

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
            ;; Attempts to retrieve the name and namespace associated with the given NFT ID.
            (name-and-namespace (unwrap! (get-bns-from-id id) ERR-NO-NAME))
            ;; Extracts the namespace part from the retrieved name-and-namespace tuple.
            (namespace (get namespace name-and-namespace))
            ;; Extracts the name part from the retrieved name-and-namespace tuple.
            (name (get name name-and-namespace))
            ;; Fetches properties of the identified namespace to confirm its existence and retrieve management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the manager of the namespace.
            (namespace-manager (get namespace-manager namespace-props))
            ;; Gets the name-props
            (name-props (unwrap! (map-get? name-properties name-and-namespace) ERR-NO-NAME))
            ;; Gets the registered-at value
            (registered-at-value (get registered-at name-props))
            ;; Gets the imported-at value
            (imported-at-value (get imported-at name-props))
            ;; Gets the current owner of the name from the name-props
            (name-current-owner (get owner name-props))
            ;; Revalidate the name current owner
            (nft-current-owner (unwrap! (nft-get-owner? BNS-V2 id) ERR-NO-NAME))
        )
        ;; Checks if the name was registered
        (match registered-at-value
            is-registered
            ;; If it was registered, check if registered-at is lower than current blockheight
            ;; This check works to make sure that if a name is fast-claimed they have to wait 1 block to transfer it
            (asserts! (< is-registered block-height) ERR-OPERATION-UNAUTHORIZED)
            ;; If it is not registered then continue
            true 
        )
        ;; Checks if the namespace is managed.
        (match namespace-manager 
            manager
            ;; If the namespace is managed, performs the transfer under the management's authorization.
            ;; Asserts that the transaction caller is the namespace manager, hence authorized to handle the transfer.
            (if (is-eq true (get manager-transferable namespace-props)) 
                ;; If manager transfers are allowed then check if contract-caller is manager
                (asserts! (is-eq contract-caller manager) ERR-NOT-AUTHORIZED)
                ;;If manager trnasfers are not allowed, then check if tx-sender is the name-current-owner
                (asserts! (is-eq tx-sender name-current-owner nft-current-owner) ERR-NOT-AUTHORIZED)
            )
            ;; If the namespace does not have a manager then...
            ;; Asserts that the transaction sender is the owner of the NFT to authorize the transfer.
            (asserts! (is-eq tx-sender name-current-owner nft-current-owner) ERR-NOT-AUTHORIZED)
        ) 
        ;; Ensures the NFT is not currently listed in the market, which would block transfers.
        (asserts! (is-none (map-get? market id)) ERR-LISTED)
        ;; Transfer ownership and update the linked lists
        (transfer-ownership-updates id owner recipient)
        ;; Updates the name-props map with the new information, everything stays the same, we only change the zonefile to none for a clean slate and the owner
        (map-set name-properties name-and-namespace (merge name-props {zonefile-hash: none, owner: recipient}))
        ;; Executes the NFT transfer from owner to recipient if all conditions are met.
        (nft-transfer? BNS-V2 id name-current-owner recipient)
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
            ;; Gets the registered-at value
            (registered-at-value (get registered-at name-props))
            ;; Gets the imported-at value
            (imported-at-value (get imported-at name-props))
            ;; Creates a listing record with price and commission details
            (listing {price: price, commission: (contract-of comm-trait)})
        )
        ;; Checks if the name was registered
        (match registered-at-value
            is-registered
            ;; If it was registered, check if registered-at is lower than current blockheight + 1
            (asserts! (<= (+ is-registered u1) block-height) ERR-OPERATION-UNAUTHORIZED)
            ;; If it is not registered then continue
            true 
        )
        ;; Check if there is a namespace manager
        (match namespace-manager 
            manager 
            ;; If there is then check that the contract-caller is the manager
            (asserts! (is-eq manager contract-caller) ERR-NOT-AUTHORIZED)
            ;; If there isn't assert that the owner is the tx-sender
            (asserts! (is-eq (some tx-sender) (nft-get-owner? BNS-V2 id)) ERR-NOT-AUTHORIZED)
        )
        
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
    (let
        (
            ;; Attempts to retrieve the name and namespace associated with the given NFT ID. If not found, it returns an error.
            (name-and-namespace (unwrap! (map-get? index-to-name id) ERR-NO-NAME))
            ;; Attempts to retrieve market map of the name
            (market-map (unwrap! (map-get? market id) ERR-NOT-LISTED))
            ;; Extracts the namespace part from the retrieved name-and-namespace tuple.
            (namespace (get namespace name-and-namespace))
            ;; Extracts the name part from the retrieved name-and-namespace tuple.
            (name (get name name-and-namespace))
            ;; Fetches properties of the identified namespace to confirm its existence and retrieve management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the manager of the namespace, if one is set.
            (namespace-manager (get namespace-manager namespace-props))
        )
        ;; Check if there is a namespace manager
        (match namespace-manager 
            manager 
            ;; If there is then check that the contract-caller is the manager
            (asserts! (is-eq manager contract-caller) ERR-NOT-AUTHORIZED)
            ;; If there isn't assert that the owner is the tx-sender
            (asserts! (is-eq (some tx-sender) (nft-get-owner? BNS-V2 id)) ERR-NOT-AUTHORIZED)
        )
        ;; Deletes the listing from the market map
        (map-delete market id)
        ;; Prints unlisting details
        (ok (print {a: "unlist-in-ustx", id: id}))
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
            (owner (unwrap! (nft-get-owner? BNS-V2 id) ERR-NO-NAME))
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
        (try! (purchase-transfer id owner tx-sender))
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
            (owner (unwrap! (nft-get-owner? BNS-V2 primary-name-id) ERR-NO-NAME))
            ;; Retrieves the current primary name for the caller, to check if an update is necessary. This should never cause an error unless the user doesn't own any BNS names
            (current-primary-name (unwrap! (map-get? primary-name tx-sender) ERR-NO-BNS-NAMES-OWNED))
            ;; Retrieves the name and namespace from the uint/index
            (name-and-namespace (unwrap! (get-bns-from-id primary-name-id) ERR-NO-NAME))
        ) 
        ;; Verifies that the caller (`tx-sender`) is indeed the owner of the name they wish to set as primary.
        (asserts! (is-eq owner tx-sender) ERR-NOT-AUTHORIZED)
        ;; Ensures the new primary name is different from the current one to avoid redundant updates.
        (asserts! (not (is-eq primary-name-id current-primary-name)) ERR-ALREADY-PRIMARY-NAME)
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
            (name-and-namespace (unwrap! (get-bns-from-id id) ERR-NO-NAME))
            ;; Extracts the namespace part from the retrieved name-and-namespace tuple.
            (namespace (get namespace name-and-namespace))
            ;; Fetches existing properties of the namespace to confirm its existence and retrieve management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Retrieves the current manager of the namespace from the namespace properties.
            (current-namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-NO-NAMESPACE-MANAGER))
            ;; Retrieves the current owner of the NFT, necessary to execute the burn operation.
            (current-name-owner (unwrap! (nft-get-owner? BNS-V2 id) ERR-UNWRAP))
            ;; Get if it is listed
            (is-listed (map-get? market id))
        ) 
        ;; Ensures that the function caller is the current namespace manager, providing the authority to perform the burn.
        (asserts! (is-eq contract-caller current-namespace-manager) ERR-NOT-AUTHORIZED)
        ;; Check if the nft is listed 
        (match is-listed
            listed
            ;; If it is listed then unlist
            (try! (unlist-in-ustx id))
            {a: "not-listed", id: id}
        )
        ;; Burn the name
        (unwrap! (burn-name-updates id) ERR-BURN-UPDATES-FAILED)
        ;; Deletes the maps
        (map-delete name-properties name-and-namespace)
        ;; Executes the burn operation for the specified NFT, effectively removing it from circulation.
        (nft-burn? BNS-V2 id current-name-owner)
    )
)

;; This function transfers the management role of a specific namespace to a new principal.
(define-public (mng-manager-transfer (new-manager principal) (namespace (buff 20)))
    (let 
        (
            ;; Fetches existing properties of the namespace to verify its existence and current management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))

            ;; Extracts the current manager of the namespace from the retrieved properties.
            (current-namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-NO-NAMESPACE-MANAGER))
        ) 
        ;; Verifies that the caller of the function is the current namespace manager to authorize the management transfer.
        (asserts! (is-eq contract-caller current-namespace-manager) ERR-NOT-AUTHORIZED)

        ;; If the checks pass, updates the namespace entry with the new manager's principal.
        ;; Retains other properties such as the launched time and the lifetime of names.
        (ok 
            (map-set namespaces namespace 
                (merge 
                    namespace-props 
                    {
                        ;; Updates the namespace-manager field to the new manager's principal.
                        namespace-manager: (some new-manager),
                    }
                )
                
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
                ;; If a previous preorder exists, check that it has expired based on the PREORDER-CLAIMABILITY-TTL.
                (>= block-height (+ PREORDER-CLAIMABILITY-TTL (unwrap! (get created-at former-preorder) ERR-PREORDER-ALREADY-EXISTS))) 
                ;; Proceed if no previous preorder exists.
                true 
            ) 
            ERR-PREORDER-ALREADY-EXISTS
        )
        ;; Validate that the hashed-salted-namespace is exactly 20 bytes long to conform to expected hash standards.
        (asserts! (is-eq (len hashed-salted-namespace) HASH160LEN) ERR-HASH-MALFORMED)
        ;; Confirm that the STX amount to be burned is positive
        (asserts! (> stx-to-burn u0) ERR-STX-BURNT-INSUFFICIENT)
        ;; Execute the token burn operation, deducting the specified STX amount from the buyer's balance.
        (try! (stx-burn? stx-to-burn tx-sender))
        ;; Record the preorder details in the `namespace-preorders` map
        (map-set namespace-preorders
            { hashed-salted-namespace: hashed-salted-namespace, buyer: tx-sender }
            { created-at: block-height, stx-burned: stx-to-burn }
        )
        ;; Return the block height at which the preorder claimability expires, based on the PREORDER-CLAIMABILITY-TTL.
        (ok (+ block-height PREORDER-CLAIMABILITY-TTL))
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
            (preorder (unwrap! (map-get? namespace-preorders { hashed-salted-namespace: hashed-salted-namespace, buyer: tx-sender }) ERR-PREORDER-NOT-FOUND))
            ;; Calculate the namespace's registration price for validation. Using the price tiers in the NAMESPACE-PRICE-TIERS
            (namespace-price (try! (get-namespace-price namespace)))
            ;; Get the namespace props to see if it already exists
            (namespace-props (map-get? namespaces namespace))
        )
        ;; Ensure the namespace consists of valid characters only.
        (asserts! (not (has-invalid-chars namespace)) ERR-CHARSET-INVALID)
        ;; Check that the namespace is available for reveal (not already existing or expired).
        (asserts! (unwrap! (can-namespace-be-registered namespace) ERR-NAMESPACE-ALREADY-EXISTS) ERR-NAMESPACE-ALREADY-EXISTS)
        ;; Verify the burned amount during preorder meets or exceeds the namespace's registration price.
        (asserts! (>= (get stx-burned preorder) namespace-price) ERR-STX-BURNT-INSUFFICIENT)
        ;; Confirm the reveal action is performed within the allowed timeframe from the preorder.
        (asserts! (< block-height (+ (get created-at preorder) PREORDER-CLAIMABILITY-TTL)) ERR-PREORDER-CLAIMABILITY-EXPIRED)
        ;; To avoid namespace snipping make sure that 1 block has passed after the preorder
        (asserts! (> block-height (+ (get created-at preorder) u1)) ERR-OPERATION-UNAUTHORIZED)
        ;; Check if the namespace manager is assigned
        (match namespace-manager 
            namespace-m
            ;; If namespace-manager is assigned, then assign everything except the lifetime, that is set to u0 sinces renewals will be made in the namespace manager contract and set the can update price function to false, since no changes will ever need to be made there
            (map-set namespaces namespace
                {
                    ;; Added manager here
                    namespace-manager: namespace-manager,
                    manager-transferable: true,
                    namespace-import: namespace-import,
                    revealed-at: block-height,
                    launched-at: none,
                    lifetime: u0,
                    can-update-price-function: false,
                    price-function: price-function 
                }
            )
            ;; If it is none then assign everything
            (map-set namespaces namespace
                {
                    ;; Added manager here
                    namespace-manager: none,
                    manager-transferable: false,
                    namespace-import: namespace-import,
                    revealed-at: block-height,
                    launched-at: none,
                    lifetime: lifetime,
                    can-update-price-function: true,
                    price-function: price-function 
                }
            )
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
            ;; Fetch the list of imported names for the namespace
            (imported-list-of-names (default-to (list) (map-get? imported-names namespace)))
        )
        ;; Ensure the transaction sender is the namespace's designated import principal, confirming their authority to launch it.
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-OPERATION-UNAUTHORIZED)
        ;; Verify the namespace has not already been launched to prevent re-launching.
        (asserts! (is-none (get launched-at namespace-props)) ERR-NAMESPACE-ALREADY-LAUNCHED)
        ;; Confirm that the action is taken within the permissible time frame since the namespace was revealed.
        (asserts! (< block-height (+ (get revealed-at namespace-props) NAMESPACE-LAUNCHABILITY-TTL)) ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED)
        ;; Update the `namespaces` map with the newly launched status of the namespace.
        (map-set namespaces namespace (merge namespace-props { launched-at: (some block-height) }))      
        ;; Update all the imported names renewal height to start with the launched-at block height
        (map update-renewal-height imported-list-of-names)
        ;; Emit an event to indicate the namespace is now ready and launched.
        (print { namespace: namespace, status: "ready", properties: (map-get? namespaces namespace) })
        ;; Confirm the successful launch of the namespace.
        (ok true)
    )
)

;; Switch function for manager-transaferable
(define-public (turn-off-manager-transfers (namespace (buff 20)))
    (let 
        (
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            (namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-NO-NAMESPACE-MANAGER))
            (launched (unwrap! (get launched-at namespace-props) ERR-NAMESPACE-NOT-LAUNCHED))
        ) 
        (asserts! (is-eq contract-caller namespace-manager) ERR-NOT-AUTHORIZED)
        (map-set namespaces namespace (merge namespace-props {manager-transferable: false}))
        (ok true)
    )
)

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
(define-public (name-import (namespace (buff 20)) (name (buff 48)) (beneficiary principal) (zonefile-hash (buff 20)) (stx-burn uint))
    (let 
        (
            ;; Fetch properties of the specified namespace to ensure it exists and to check its current state.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Fetch the latest index to mint
            (current-mint (+ (var-get bns-index) u1))
            ;; Fetch the primary name of the beneficiary
            (beneficiary-primary-name (map-get? primary-name beneficiary))
            ;; Fetch the list of imported names for the namespace
            (imported-list-of-names (default-to (list) (map-get? imported-names namespace)))
        )
        ;; Ensure the name is not already registered, triple check
        (asserts! (map-insert name-to-index {name: name, namespace: namespace} current-mint) ERR-NAME-NOT-AVAILABLE)
        (asserts! (map-insert index-to-name current-mint {name: name, namespace: namespace}) ERR-NAME-NOT-AVAILABLE)
        (asserts! (map-insert bns-name-owner current-mint beneficiary) ERR-NAME-NOT-AVAILABLE) 
        ;; Verify that the name contains only valid characters to ensure compliance with naming conventions.
        (asserts! (not (has-invalid-chars name)) ERR-CHARSET-INVALID)
        ;; Ensure the transaction sender is the namespace's designated import principal, confirming their authority to import names.
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-OPERATION-UNAUTHORIZED)
        ;; Check that the namespace has not been launched yet, as names can only be imported to namespaces that are revealed but not launched.
        (asserts! (is-none (get launched-at namespace-props)) ERR-NAMESPACE-ALREADY-LAUNCHED)
        ;; Confirm that the import is occurring within the allowed timeframe since the namespace was revealed.
        (asserts! (< block-height (+ (get revealed-at namespace-props) NAMESPACE-LAUNCHABILITY-TTL)) ERR-NAMESPACE-PREORDER-LAUNCHABILITY-EXPIRED)
        ;; Set the name properties
        (map-set name-properties {name: name, namespace: namespace}
            {
                registered-at: none,
                imported-at: (some block-height),
                revoked-at: false,
                zonefile-hash: (some zonefile-hash),
                fully-qualified-name: none,
                preordered-by: none,
                renewal-height: (+ (get lifetime namespace-props) block-height),
                stx-burn: stx-burn,
                owner: beneficiary,
            }
        )
        ;; Update the index of the minting
        (var-set bns-index current-mint)
        ;; Update the imported names list for the namespace
        (map-set imported-names namespace (unwrap! (as-max-len? (append imported-list-of-names current-mint) u1000) ERR-OVERFLOW))
        (add-name-to-principal-updates beneficiary current-mint)
        ;; Mint the name to the beneficiary
        (try! (nft-mint? BNS-V2 current-mint beneficiary))
        ;; Log the new name registration
        (print 
            {
                topic: "new-name",
                owner: beneficiary,
                name: {name: name, namespace: namespace},
                id: current-mint,
            }
        )
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
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-OPERATION-UNAUTHORIZED)
        ;; Verify that the namespace's price function is still allowed to be updated.
        (asserts! (get can-update-price-function namespace-props) ERR-OPERATION-UNAUTHORIZED)
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
        (asserts! (is-eq (get namespace-import namespace-props) tx-sender) ERR-OPERATION-UNAUTHORIZED)
        ;; Update the namespace properties in the `namespaces` map, setting `can-update-price-function` to false.
        ;; This action effectively locks the price function, preventing any future changes.
        (map-set namespaces namespace 
            (merge namespace-props { can-update-price-function: false })
        )
        ;; Return a success confirmation, indicating the price function update capability has been successfully revoked.
        (ok true)
    )
)

;; NEW FAST MINT
;; A 'fast' one-block registration function: (name-claim-fast)
(define-public (name-claim-fast (name (buff 48)) (namespace (buff 20)) (zonefile-hash (buff 20)) (stx-burn uint) (send-to principal)) 
    (let 
        (
            ;; Retrieves existing properties of the namespace to confirm its existence and management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the current manager of the namespace to verify the authority of the caller.
            (current-namespace-manager (get namespace-manager namespace-props))
            ;; Calculates the ID for the new name to be minted, incrementing the last used ID.
            (id-to-be-minted (+ (var-get bns-index) u1))
            ;; Tries to retrieve the name and namespace to see if it already exists
            (name-props (map-get? name-properties {name: name, namespace: namespace}))
        )
        ;; Ensure the name is not already registered, triple check
        (asserts! (map-insert name-to-index {name: name, namespace: namespace} id-to-be-minted) ERR-NAME-NOT-AVAILABLE)
        (asserts! (map-insert index-to-name id-to-be-minted {name: name, namespace: namespace}) ERR-NAME-NOT-AVAILABLE)
        (asserts! (map-insert bns-name-owner id-to-be-minted send-to) ERR-NAME-NOT-AVAILABLE) 
        ;; Checks if that name already exists for the namespace if it does, then don't mint
        (asserts! (is-none name-props) ERR-NAME-NOT-AVAILABLE)
        ;; Verifies if the namespace has a manager
        (match current-namespace-manager 
            manager 
            ;; If it does
            (asserts! (is-eq contract-caller manager) ERR-NOT-AUTHORIZED)
           
            ;; If it doesn't
            (begin 
                ;; Asserts tx-sender is the send-to
                (asserts! (is-eq tx-sender send-to) ERR-NOT-AUTHORIZED)
                ;; Burns the STX from the user
                (try! (stx-burn? stx-burn send-to))
                ;; Confirms that the amount of STX burned with the preorder is sufficient for the name registration based on a computed price.
                (asserts! (>= stx-burn (try! (compute-name-price name (get price-function namespace-props)))) ERR-STX-BURNT-INSUFFICIENT)
            )
        )
        ;; Set the index 
        (var-set bns-index id-to-be-minted)
        ;; Sets properties for the newly registered name including registration time, price, owner, and associated zonefile hash.
        (map-set name-properties
            {
                name: name, namespace: namespace
            } 
            {
               
                registered-at: (some (+ block-height u1)),
                imported-at: none,
                revoked-at: false,
                zonefile-hash: (some zonefile-hash),
                fully-qualified-name: none,
                preordered-by: none,
                renewal-height: (+ (get lifetime namespace-props) block-height),
                stx-burn: stx-burn,
                owner: send-to,
            }
        )
        (add-name-to-principal-updates send-to id-to-be-minted)
        ;; Mints the new BNS name as an NFT, assigned to the 'send-to' principal.
        (try! (nft-mint? BNS-V2 id-to-be-minted send-to))
        ;; Log the new name registration
        (print 
            {
                topic: "new-name",
                owner: send-to,
                name: {name: name, namespace: namespace},
                id: id-to-be-minted,
            }
        )
        ;; Signals successful completion of the registration process.
        (ok true)
    )
)

;; Defines a public function called `name-preorder`.
;; This function is responsible for preordering BNS name by burning the registration fee and submitting the salted hash of the name with the namespace included.
;; This function is callable by ANYONE, regular users or namespace managers, the real check happens in the name-register function. Only regular users who preorder a name through this function should be able to mint a name trough the register-name function
(define-public (name-preorder (hashed-salted-fqn (buff 20)) (stx-to-burn uint))
    (let 
        (
            ;; Attempt to retrieve a previous preorder from the 'name-preorders' map using the hashed-salted FQN and the tx-sender's address as keys.
            ;; This checks if the same user has already preordered the same name.
            (former-preorder (map-get? name-preorders { hashed-salted-fqn: hashed-salted-fqn, buyer: tx-sender }))
        )
        ;; Checks if there was a previous preorder and if it has expired.
        (asserts! 
            (match former-preorder
                preorder
                ;; Checks if the current block height is greater than or equal to the creation time of the previous preorder plus the TTL.
                ;; This determines if the previous preorder has expired.
                (>= block-height (+ PREORDER-CLAIMABILITY-TTL (unwrap! (get created-at former-preorder) ERR-UNWRAP)))
                ;; If no previous preorder is found, then true, allowing the process to continue.
                true
            )
            ;; If a previous preorder is still valid/not expired, return an error indicating that a duplicate active preorder exists.
            ERR-NAME-PREORDER-ALREADY-EXISTS
        )
        ;; Validates that the length of the hashed and salted FQN is exactly 20 bytes.
        ;; This ensures that the input conforms to the expected hash format.
        (asserts! (is-eq (len hashed-salted-fqn) HASH160LEN) ERR-HASH-MALFORMED)
        ;; Ensures that the amount of STX specified to burn is greater than zero.
        (asserts! (> stx-to-burn u0) ERR-STX-BURNT-INSUFFICIENT)
        ;; Burns the specified amount of STX tokens from the tx-sender
        ;; This operation fails if the sender does not have enough tokens, returns an insufficient funds error.
        (try! (stx-burn? stx-to-burn tx-sender))
        ;; Records the preorder in the 'name-preorders' map.
        ;; It includes the hashed-salted FQN, the tx-sender as the buyer, the current block height, the amount of STX burned
        (map-set name-preorders
            { hashed-salted-fqn: hashed-salted-fqn, buyer: tx-sender }
            { created-at: block-height, stx-burned: stx-to-burn}
        )
        ;; Returns the block height at which the preorder's claimability period will expire.
        ;; This is calculated by adding the PREORDER-CLAIMABILITY-TTL to the current block height.
        (ok (+ block-height PREORDER-CLAIMABILITY-TTL))
    )
)

;; Defines a public function `name-register` that finalizes the registration of a BNS name.
;; This function uses provided details to verify the preorder, register the name, and assign it initial properties.
;; This should only allow users from UNMANAGED namespaces to register names
(define-public (name-register (namespace (buff 20)) (name (buff 48)) (salt (buff 20)) (zonefile-hash (buff 20)))
    (let 
        (
            ;; Generates the hashed, salted fully-qualified name by concatenating the name, namespace, and salt, then applying a hash160 function.
            (hashed-salted-fqn (hash160 (concat (concat (concat name 0x2e) namespace) salt)))
            ;; Retrieves the preorder details from the `name-preorders` map using the hashed-salted FQN to ensure the preorder exists and belongs to the tx-sender.
            (preorder (unwrap! (map-get? name-preorders { hashed-salted-fqn: hashed-salted-fqn, buyer: tx-sender }) ERR-PREORDER-NOT-FOUND))
            ;; Retrieves the properties of the namespace to confirm its existence and check its management settings.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the current manager of the namespace to ensure only authorized actions are performed.
            (current-namespace-manager (get namespace-manager namespace-props))
            ;; Generates a new ID for the name to be registered, incrementing the last used ID in the BNS system.
            (id-to-be-minted (+ (var-get bns-index) u1))
            ;; Checks if the name and namespace combination already exists in the system.
            (name-props (map-get? name-properties {name: name, namespace: namespace}))
            ;; Gets the registered-at height to further checks
            (created-at-height (get registered-at name-props))
            ;; Retrieves the index of the name if it exists, to check for prior registrations.
            (name-index (map-get? name-to-index {name: name, namespace: namespace}))
            ;; Get the height of my preorder
            (tx-sender-preorder-height (get created-at preorder))
        )
        ;; Ensures that the namespace does not have a manager.
        (asserts! (is-none current-namespace-manager) ERR-NOT-AUTHORIZED)
        ;; Validates that the preorder was made after the namespace was officially launched.
        (asserts! (> (get created-at preorder) (unwrap! (get launched-at namespace-props) ERR-UNWRAP)) ERR-NAME-PREORDERED-BEFORE-NAMESPACE-LAUNCH)
        ;; Verifies the registration is completed within the claimability period defined by the PREORDER-CLAIMABILITY-TTL.
        (asserts! (< block-height (+ (get created-at preorder) PREORDER-CLAIMABILITY-TTL)) ERR-PREORDER-CLAIMABILITY-EXPIRED)
        ;; Verifies that 1 block has passed from when the preorder was made
        (asserts! (> block-height (+ (get created-at preorder) u1)) ERR-NAME-NOT-CLAIMABLE-YET)
        ;; Confirms that the amount of STX burned with the preorder is sufficient for the name registration based on a computed price.
        (asserts! (>= (get stx-burned preorder) (try! (compute-name-price name (get price-function namespace-props)))) ERR-STX-BURNT-INSUFFICIENT)
        ;; Check if the name is registered or not
        (match name-props
            name-props-exist 
            ;; If it is some, then it is registered and the name exists... we need to do further checks
            (begin
                ;; First check that the current owner is not the tx-sender
                (asserts! (not (is-eq tx-sender (get owner name-props-exist))) ERR-OWNER-IS-THE-SAME)
                ;; If the owner and the tx sender are not the same then check if the name was registered
                (match (get registered-at name-props-exist) 
                    registered
                    ;; If it was registered then check the fully-qualified-name of the name-props to see if it was preordered or fast-minted
                    (match (get fully-qualified-name name-props-exist) 
                        fqn 
                        ;; If it was preordered we have to compare which one was made first, if the recorded preorder or the tx-sender's
                        ;; If created-at from the first preorder is bigger than the tx-sender-preorder-height then return true and continue, if it not bigger then return false, indicating that the first preorder happened before
                        (begin 
                            (asserts! (> (unwrap-panic (get created-at (map-get? name-preorders {hashed-salted-fqn: fqn, buyer: (unwrap-panic (get preordered-by name-props-exist))}))) tx-sender-preorder-height) ERR-PREORDERED-BEFORE) 
                            ;; And also update the map to have the correct preorder used to register the name
                            ;; Update to the correct fqn and the correct preordered-by principal
                            (map-set name-properties {name: name, namespace: namespace} (merge name-props-exist {fully-qualified-name: (some hashed-salted-fqn), preordered-by: (some tx-sender)}))
                        )
                        ;; If the name was not preordered it means it was fast minted
                        ;; If it does then compare the 2 heights
                        (begin 
                            (asserts! (> registered tx-sender-preorder-height) ERR-FAST-MINTED-BEFORE)   
                            ;; Update to the correct preordered-by principal
                            (map-set name-properties {name: name, namespace: namespace} (merge name-props-exist {preordered-by: (some tx-sender)}))
                        )
                        
                    )
                    ;; If the name was not registered then it was imported so we need to check agains that
                    (asserts! (> (unwrap-panic (get imported-at (unwrap-panic name-props))) tx-sender-preorder-height) ERR-IMPORTED-BEFORE)
                )
                ;; If any of both scenarios are true then purchase-transfer the name
                (try! (purchase-transfer (unwrap-panic name-index) (get owner name-props-exist) tx-sender))
            ) 
            ;; If it is none then it is not registered then execute all actions required to mint a new name
            (begin
                ;; Ensure the name is not already registered, triple check
                (asserts! (map-insert name-to-index {name: name, namespace: namespace} id-to-be-minted) ERR-NAME-NOT-AVAILABLE)
                (asserts! (map-insert index-to-name id-to-be-minted {name: name, namespace: namespace}) ERR-NAME-NOT-AVAILABLE)
                (asserts! (map-insert bns-name-owner id-to-be-minted tx-sender) ERR-NAME-NOT-AVAILABLE)
                ;; Sets properties for the newly registered name including registration time, price, owner, and associated zonefile hash.
                (map-set name-properties
                    {
                        name: name, namespace: namespace
                    } 
                    {
                        registered-at: (some block-height),
                        imported-at: none,
                        revoked-at: false,
                        zonefile-hash: (some zonefile-hash),
                        fully-qualified-name: (some hashed-salted-fqn),
                        preordered-by: (some tx-sender),
                        renewal-height: (+ (get lifetime namespace-props) block-height),
                        stx-burn: (get stx-burned preorder),
                        owner: tx-sender,
                    }
                )
                ;; Links the new ID to the name and namespace.
                (map-set index-to-name id-to-be-minted {name: name, namespace: namespace})
                ;; Links the name and namespace to the new ID.
                (map-set name-to-index {name: name, namespace: namespace} id-to-be-minted)
                ;; Updates the BNS-index var
                (var-set bns-index id-to-be-minted)
                (add-name-to-principal-updates tx-sender id-to-be-minted)
                ;; Mints the BNS name as an NFT and assigns it to the tx sender.
                (try! (nft-mint? BNS-V2 id-to-be-minted tx-sender))
            )       
        )
        ;; Log the new name registration
        (print 
            {
                topic: "new-name",
                owner: tx-sender,
                name: {name: name, namespace: namespace},
                id: id-to-be-minted,
            }
        )
        ;; Confirms successful registration of the name.
        (ok true)
    )
)

;; Defines a public function called `mng-name-preorder`.
;; This function is similar to `name-preorder` but only for namespace managers, without the burning of STX tokens.
;; This function is intended only for managers, but in reality anyone can call this, but the mng-name-register and name-register will validate everything
(define-public (mng-name-preorder (hashed-salted-fqn (buff 20)))
    (let 
        (
            ;; Attempt to retrieve a previous preorder from the 'name-preorders' map using the hashed-salted FQN and the contract-caller address as keys.
            ;; This checks if the same user has already preordered the same name.
            (former-preorder (map-get? name-preorders { hashed-salted-fqn: hashed-salted-fqn, buyer: contract-caller }))
        )
        ;; Checks if there was a previous preorder and if it has expired.
        (asserts! 
            (match former-preorder
                preorder
                ;; Checks if the current block height is greater than or equal to the creation time of the previous preorder plus the TTL.
                ;; This determines if the previous preorder has expired.
                (>= block-height (+ PREORDER-CLAIMABILITY-TTL (unwrap! (get created-at former-preorder) ERR-UNWRAP)))
                ;; If no previous preorder is found, then true, allowing the process to continue.
                true
            )
            ;; If a previous preorder is still valid/not expired, return an error indicating that a duplicate active preorder exists.
            ERR-NAME-PREORDER-ALREADY-EXISTS
        )
        ;; Validates that the length of the hashed and salted FQN is exactly 20 bytes.
        ;; This ensures that the salt conforms to the expected hash160 output length.
        (asserts! (is-eq (len hashed-salted-fqn) HASH160LEN) ERR-HASH-MALFORMED)
        ;; Records the preorder in the 'name-preorders' map.
        ;; It includes the hashed-salted FQN, the contract-caller as the buyer, the current block height, the amount of STX burned is set to u0
        (map-set name-preorders
            { hashed-salted-fqn: hashed-salted-fqn, buyer: contract-caller }
            { created-at: block-height, stx-burned: u0 }
        )
        ;; Returns the block height at which the preorder's claimability period will expire.
        ;; This is calculated by adding the PREORDER-CLAIMABILITY-TTL to the current block height.
        (ok (+ block-height PREORDER-CLAIMABILITY-TTL))
    )
)

;; Defines a public function `name-register` that finalizes the registration of a BNS name.
;; This function uses provided details to verify the preorder, register the name, and assign it initial properties.
;; This should only allow Managers from MANAGED namespaces to register names
(define-public (mng-name-register (namespace (buff 20)) (name (buff 48)) (salt (buff 20)) (zonefile-hash (buff 20)) (send-to principal))
    (let 
        (
            ;; Generates the hashed, salted fully-qualified name by concatenating the name, namespace, and salt, then applying a hash160 function.
            (hashed-salted-fqn (hash160 (concat (concat (concat name 0x2e) namespace) salt)))
            ;; Retrieves the existing properties of the namespace to confirm its existence and management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the current manager of the namespace to verify the authority of the caller, ensuring only the namespace manager can perform this action.
            (current-namespace-manager (unwrap! (get namespace-manager namespace-props) ERR-NO-NAMESPACE-MANAGER))
            ;; Retrieves the preorder information using the hashed-salted FQN to verify the preorder exists and is associated with the current namespace manager.
            (preorder (unwrap! (map-get? name-preorders { hashed-salted-fqn: hashed-salted-fqn, buyer: current-namespace-manager }) ERR-PREORDER-NOT-FOUND))
            ;; Calculates the ID for the new name to be minted, incrementing the last used ID in the BNS system.
            (id-to-be-minted (+ (var-get bns-index) u1))
            ;; Checks if the name is already registered within the namespace.
            (name-props (map-get? name-properties {name: name, namespace: namespace}))
            ;; Retrieves the index of the name, if it exists, to check for prior registrations.
            (name-index (map-get? name-to-index {name: name, namespace: namespace}))
        )
        ;; Ensure the name is not already registered, triple check
        (asserts! (map-insert name-to-index {name: name, namespace: namespace} id-to-be-minted) ERR-NAME-NOT-AVAILABLE)
        (asserts! (map-insert index-to-name id-to-be-minted {name: name, namespace: namespace}) ERR-NAME-NOT-AVAILABLE)
        (asserts! (map-insert bns-name-owner id-to-be-minted send-to) ERR-NAME-NOT-AVAILABLE) 
        ;; Verifies that the caller of the contract is the namespace manager.
        (asserts! (is-eq contract-caller current-namespace-manager) ERR-NOT-AUTHORIZED)
        ;; Ensures the name is not already registered by checking if it lacks an existing index.
        (asserts! (is-none name-index) ERR-NO-NAME)
        ;; Validates that the preorder was made after the namespace was officially launched.
        (asserts! (> (get created-at preorder) (unwrap! (get launched-at namespace-props) ERR-UNWRAP)) ERR-NAME-PREORDERED-BEFORE-NAMESPACE-LAUNCH)
        ;; Verifies the registration is completed within the claimability period defined by the PREORDER-CLAIMABILITY-TTL.
        (asserts! (< block-height (+ (get created-at preorder) PREORDER-CLAIMABILITY-TTL)) ERR-PREORDER-CLAIMABILITY-EXPIRED)
        ;; Sets properties for the newly registered name including registration time, price, owner, and associated zonefile hash.
        (map-set name-properties
            {
                name: name, namespace: namespace
            } 
            {
                registered-at: (some block-height),
                imported-at: none,
                revoked-at: false,
                zonefile-hash: (some zonefile-hash),
                fully-qualified-name: (some hashed-salted-fqn),
                preordered-by: (some send-to),
                renewal-height: (+ (get lifetime namespace-props) block-height),
                stx-burn: u0,
                owner: send-to,
            }
        )
        ;; Updates BNS-index variable to the newly minted ID.
        (var-set bns-index id-to-be-minted)
        (add-name-to-principal-updates send-to id-to-be-minted)
        ;; Mints the BNS name as an NFT to the send-to address, finalizing the registration.
        (try! (nft-mint? BNS-V2 id-to-be-minted send-to))
        ;; Log the new name registration
        (print 
            {
                topic: "new-name",
                owner: send-to,
                name: {name: name, namespace: namespace},
                id: id-to-be-minted,
            }
        )
        ;; Confirms successful registration of the name.
        (ok true)
    )
)

;; update-zonefile-hash
;; A update-zonefile-hash transaction changes the name's zone file hash. You would send one of these transactions 
;; if you wanted to change the name's zone file contents. 
;; For example, you would do this if you want to deploy your own Gaia hub and want other people to read from it.

;; Public function `update-zonefile-hash` for changing the zone file hash associated with a name.
;; This operation is typically used to update the zone file contents of a name, such as when deploying a new Gaia hub.
;; @params:
    ;; namespace (buff 20): The namespace of the name whose zone file hash is being updated.
    ;; name (buff 48): The name whose zone file hash is being updated.
    ;; zonefile-hash (buff 20): The new zone file hash to be associated with the name.
(define-public (update-zonefile-hash (namespace (buff 20)) (name (buff 48)) (zonefile-hash (buff 20)))
    (let 
        (
            ;; Get index from name and namespace
            (index-id (unwrap! (map-get? name-to-index {name: name, namespace: namespace}) ERR-NO-NAME))
            ;; Get the owner
            (owner (unwrap! (nft-get-owner? BNS-V2 index-id) ERR-UNWRAP))
            ;; Get name props
            (name-props (unwrap! (map-get? name-properties {name: name, namespace: namespace}) ERR-NO-NAME))
            ;; Get namespace props
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
            ;; Get the renewal height
            (renewal (get renewal-height name-props))
            ;; Get the current zonefile
            (current-zone-file (get zonefile-hash name-props))
        )
        ;; Assert we are actually updating the zonefile
        (asserts! (not (is-eq (some zonefile-hash) current-zone-file)) ERR-OPERATION-UNAUTHORIZED)
        ;; Asserts the name has not been revoked.
        (asserts! (not (get revoked-at name-props)) ERR-NAME-REVOKED)
        ;; See if the namespace has a manager
        (asserts! 
            (match namespace-manager 
                manager 
                ;; If it does, then check contract caller is the manager
                (is-eq contract-caller manager)
                ;; If not then check that the tx-sender is the owner
                (is-eq tx-sender owner)
            ) 
            ERR-NOT-AUTHORIZED
        )
        
        ;; Assert that the name is in valid time or grace period
        (asserts! (<= block-height (+ renewal NAME-GRACE-PERIOD-DURATION)) ERR-OPERATION-UNAUTHORIZED)
        ;; Update the zonefile hash
        (map-set name-properties {name: name, namespace: namespace}
            (merge
                name-props
                {zonefile-hash: (some zonefile-hash)}
            )
        )
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
    ;; Keeping this and only modifying it enough to be able to revoke-it, don't know if we will need this so I am doing this only to assert in the update-zonefile function
(define-public (name-revoke (namespace (buff 20)) (name (buff 48)))
    (let 
        (
            ;; Retrieve the properties of the namespace to ensure it exists and is valid for registration.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
            ;; retreive the name props
            (name-props (unwrap! (map-get? name-properties {name: name, namespace: namespace}) ERR-NO-NAME))
        )
        (asserts! 
            (match namespace-manager 
                manager 
                (is-eq contract-caller manager)
                (is-eq tx-sender (get namespace-import namespace-props))
            ) 
            ERR-NOT-AUTHORIZED
        )
            
        (map-set name-properties {name: name, namespace: namespace}
            (merge 
                name-props
                {revoked-at: true} 
            )
        )
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
(define-public (name-renewal (namespace (buff 20)) (name (buff 48)) (stx-to-burn uint) (zonefile-hash (optional (buff 20))))
    (let 
        (
            ;; Get the index of the name
            (name-index (unwrap! (map-get? name-to-index {name: name, namespace: namespace}) ERR-NO-NAME))
            ;; Fetch the namespace properties from the `namespaces` map.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Get the current owner of the name.
            (owner (unwrap! (nft-get-owner? BNS-V2 name-index) ERR-NO-NAME))
            ;; Fetch the name properties from the `name-properties` map.
            (name-props (unwrap! (map-get? name-properties { name: name, namespace: namespace }) ERR-NO-NAME))
            ;; Retrieve namespace manager if any
            (namespace-manager (get namespace-manager namespace-props))
            ;; Get if the name was registered
            (name-registered (get registered-at name-props))
        )
        ;; Assert that the namespace doesn't have a manager, if it does then only the manager can renew names
        (asserts! (is-none namespace-manager) ERR-NAMESPACE-HAS-MANAGER)
        ;; Asserts that the namespace has been launched.
        (asserts! (is-some (get launched-at namespace-props)) ERR-NAMESPACE-NOT-LAUNCHED)
        ;; Asserts that renewals are required for names in this namespace
        (asserts! (> (get lifetime namespace-props) u0) ERR-OPERATION-UNAUTHORIZED)
        ;; Checks if the name's grace period has expired.
        (if (< block-height (+ (get renewal-height name-props) NAME-GRACE-PERIOD-DURATION))
            ;; If it has not expired also check if the name is in its lifetime period
            (if (< block-height (get renewal-height name-props))
                ;; If the name is in lifetime period
                (begin 
                    ;; Asserts that the sender of the transaction matches the current owner of the name.
                    (asserts! (is-eq owner tx-sender) ERR-NOT-AUTHORIZED) 
                    ;; Increase the renewal height + the lifetime of the namespace, and everything else stays the same
                    (map-set name-properties {name: name, namespace: namespace} 
                        (merge 
                            name-props
                            {renewal-height: (+ (get renewal-height name-props) (get lifetime namespace-props))}
                        )
                    )
                )
                ;; If the name is not in the lifetime period, but is in the grace period
                (begin 
                    ;; Asserts that the sender of the transaction matches the current owner of the name.
                    (asserts! (is-eq owner tx-sender) ERR-NOT-AUTHORIZED)
                    ;; Increase the renewal height by adding the lifetime of the namespace + the current block-height, and everything else stays the same
                    (map-set name-properties {name: name, namespace: namespace} 
                        (merge 
                            name-props
                            {renewal-height: (+ block-height (get lifetime namespace-props))}
                        )
                    )
                )
            )
            ;; If the name is not in grace period then anyone can claim the name
            ;; First check that it is not listed on the market
            (match (map-get? market name-index)
                listed-name 
                ;; If tha market map exists for the name-index
                (begin 
                    ;; Deletes the listing from the market map
                    (map-delete market name-index) 
                    ;; Then transfers the name and updates every map
                    (try! (purchase-transfer name-index owner tx-sender))
                    ;; Update the renewal-height
                    (map-set name-properties {name: name, namespace: namespace}
                        (merge 
                            (unwrap! (map-get? name-properties {name: name, namespace: namespace}) ERR-UNWRAP)
                            {renewal-height: (+ block-height (get lifetime namespace-props))}
                        )
                    )
                )
                ;; If the market map does not exist
                ;; Check if the current owner is the tx-sender
                (if (is-eq tx-sender owner)
                    ;; If it is true then update the renewal-height to be the current block-height + the lifetime of the namespace, to start from scratch
                    (map-set name-properties {name: name, namespace: namespace}
                        (merge 
                            name-props 
                            {renewal-height: (+ block-height (get lifetime namespace-props))}
                        )
                    )
                    ;; If the tx-sender is not the owner
                    (begin 
                        ;; transfer the name and update all maps 
                        (try! (purchase-transfer name-index owner tx-sender))
                        ;; Update the renewal-height to be the current block-height + the lifetime of the namespace
                        (map-set name-properties {name: name, namespace: namespace}
                            (merge 
                                (unwrap! (map-get? name-properties {name: name, namespace: namespace}) ERR-UNWRAP)
                                {renewal-height: (+ block-height (get lifetime namespace-props))}
                            )
                        )
                    ) 
                )
            )  
        )
        ;; Asserts that the amount of STX to be burned is at least equal to the price of the name.
        (asserts! (>= stx-to-burn (try! (compute-name-price name (get price-function namespace-props)))) ERR-STX-BURNT-INSUFFICIENT)
        ;; Asserts that the name has not been revoked.
        (asserts! (not (get revoked-at name-props)) ERR-NAME-REVOKED)
        ;; Burns the STX provided
        (try! (stx-burn? stx-to-burn tx-sender))
        ;; Checks if a new zone file hash is specified
        (match zonefile-hash
            zonefile
            ;; If it is then update it
            (try! (update-zonefile-hash namespace name zonefile))
            ;; If there isn't then continue
            false
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
        (ok (unwrap! (element-at NAMESPACE-PRICE-TIERS (min u7 (- namespace-len u1))) ERR-UNWRAP))
    )
)

;; Read-only function `can-namespace-be-registered` checks if a namespace is available for registration.
;; @params:
    ;; namespace (buff 20): The namespace being checked for availability.
(define-read-only (can-namespace-be-registered (namespace (buff 20)))
    ;; Returns the result of `is-namespace-available` directly, indicating if the namespace can be registered.
    (ok (is-namespace-available namespace))
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

;; Read only function to get name properties
(define-read-only (get-bns-info (name (buff 48)) (namespace (buff 20)))
    (map-get? name-properties {name: name, namespace: namespace})
)

;; Defines a read-only function to fetch the unique ID of a BNS name given its name and the namespace it belongs to.
(define-read-only (get-id-from-bns (name (buff 48)) (namespace (buff 20))) 
    ;; Attempts to retrieve the ID from the 'name-to-index' map using the provided name and namespace as the key.
    (map-get? name-to-index {name: name, namespace: namespace})
)

;; Defines a read-only function to fetch the unique ID of a BNS name given its name and the namespace it belongs to.
(define-read-only (get-bns-from-id (id uint)) 
    ;; Attempts to retrieve the ID from the 'name-to-index' map using the provided name and namespace as the key.
    (map-get? index-to-name id)
)

;; Fetcher for primary name
(define-read-only (get-primary-name (owner principal))
    (map-get? primary-name owner)
)

;; Define read-only function to get the balance of names for a principal
(define-read-only (get-balance (account principal))
    ;; Return balance or 0 if not found
    (default-to u0 (map-get? owner-bns-balance account)) 
)

;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
;;;;; Private ;;;;
;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;

;; Define private function to transfer ownership of a name
;; This function removes the name from the sender and adds the name to the recipient, in both cases primary name update is handled accordingly
(define-private (transfer-ownership-updates (id uint) (sender principal) (recipient principal))
    (begin
        ;; Update the owner map to set the new owner for the name ID
        (map-set bns-name-owner id recipient)
        
        ;; Log the transfer action with the topic "transfer-ownership"
        (print 
            {
                topic: "transfer-ownership",
                id: id,
                recipient: recipient,
            }
        )
        ;; Remove the name from the sender's list
        (remove-name-from-principal-updates sender id)
        ;; Add the name to the recipient's list
        (add-name-to-principal-updates recipient id)
    )
)

;; Define private function to remove a name from a principal's list.
;; Updates the principal's name list, primary name, and balance.
;; Removes the name from the principal's balance.
;; Checks if it is the primary name, and updates accordingly:
    ;; If it is, assigns the next name as primary if it exists; if not, assigns the previous name.
    ;; If neither exists, deletes the primary name map entry.
;; Updates the linked list by adjusting the next name map of the previous name of the ID being removed and previous name map of the next name of the ID being removed.
;; Deletes the linked ID maps of the ID being removed.
(define-private (remove-name-from-principal-updates (account principal) (id uint))
    (let
        (
            ;; Get the previous name ID in the list from the ID being removed.
            (prev-name (map-get? previous-name-in-list id)) 
            ;; Get the next name ID in the list from the ID being removed.
            (next-name (map-get? next-name-in-list id)) 
            ;; Get the primary name ID for the account.
            (primary (unwrap-panic (map-get? primary-name account))) 
            ;; Get the last name ID for the account.
            (last (unwrap-panic (map-get? owners-last-name account))) 
            ;; Get the balance of names for the account.
            (balance (unwrap-panic (map-get? owner-bns-balance account))) 
        )
        ;; Check if the name being removed is the primary name.
        (if (is-eq primary id)
            ;; If the ID being removed is the primary name:
            ;; Check if there is a next name from the ID.
            (match next-name next-n
                ;; If there is a next name, update the primary name to the next name.
                (map-set primary-name account next-n)
                ;; If there is no next name, then it means it is the last name.
                ;; Check if there is a previous name.
                (match prev-name prev-n 
                    ;; If there is a previous name, update the primary name to the previous name and update the owners-last-name.
                    (begin 
                        (map-set primary-name account prev-n) 
                        (map-set owners-last-name account prev-n)
                    )
                    ;; If there is also no previous name, then it must be the only name owned by the principal.
                    ;; Delete the maps so the principal doesn't have more names linked to it.
                    (begin
                        (map-delete primary-name account)
                        (map-delete owners-last-name account)
                    )
                )
            )
            ;; If the ID is not equal to the primary name, continue.
            true
        )
        
        ;; Updating the linked list:
        ;; Check if the next name exists for the ID being removed.
        (match next-name next-n 
            ;; If it exists:
            ;; Check if the previous name also exists, otherwise it is the first name on the list.
            (match prev-name prev-n
                ;; If both names exist
                ;; Set the current previous name of the ID being removed as the previous name to the next name of the ID being removed.
                (map-set previous-name-in-list next-n prev-n)
                ;; If there is no previous name for the ID being removed, it means that the next name on the list from the ID being removed becomes the first name on the list.
                ;; Delete the next name's previous name, which should correspond to the ID being removed.
                (map-delete previous-name-in-list next-n)
            )
            ;; If there is no next name, then return true.
            true
        )
        
        ;; Now check if the previous name exists.
        (match prev-name prev-n 
            ;; If it exists:
            ;; Check if the next name exists, otherwise this is the last name on the list.
            (match next-name next-n
                ;; If both names exist
                ;; Set the current next name as the next name of the previous name of the ID being removed.
                (map-set next-name-in-list prev-n next-n)
                ;; If there is no next name to the ID being removed, then it means this was the last name.
                ;; Delete the previous name's next name map so the previous name becomes the last name.
                (map-delete next-name-in-list prev-n)
            )
            ;; If there is no previous name, then return true.
            true
        )
        
        ;; Delete the next and previous name maps of the ID being removed.
        (map-delete next-name-in-list id)
        (map-delete previous-name-in-list id)

        ;; Update the balance map to decrease the balance by 1.
        (map-set owner-bns-balance account (- balance u1))
        
        ;; Return true indicating successful removal.
        true 
    )
)

;; Define private function to burn a name.
;; This function updates the primary name and linked list by calling `remove-name-from-principal-updates`.
;; It also deletes the name from all relevant maps.
(define-private (burn-name-updates (id uint))
    (let
        (
            ;; Get the name details associated with the given ID.
            (name (unwrap! (map-get? index-to-name id) ERR-NO-NAME)) 
            ;; Get the owner of the name.
            (owner (unwrap! (map-get? bns-name-owner id) ERR-UNWRAP)) 
        )
        ;; Call the function to update the owner's list and primary name.
        ;; This function handles removing the name from the principal's linked list and updating the primary name if necessary.
        (remove-name-from-principal-updates owner id)
        ;; Delete the name from all maps:
        ;; Remove the name-to-index.
        (map-delete name-to-index name)
        ;; Remove the index-to-name.
        (map-delete index-to-name id)
        ;; Remove the name-owner.
        (map-delete bns-name-owner id)
        ;; Return true indicating the successful burn of the name.
        (ok true) 
    )
)

;; Define private function to add a name to a principal's list:
;; Set it as primary-name if the principal does not have a primary name.
;; Add the name to the account's balance.
;; If it is the first name being minted by the principal:
    ;; Set it as the last name to start the list.
;; If it is not the first name being minted by the principal:
    ;; Set the new ID as the new last name to continue the list.
    ;; Set the new ID as the next name of the old last name, so we know which name follows the first name.
    ;; Set the old last name as the previous name of the new ID, so we know which name is previous to the new name.
(define-private (add-name-to-principal-updates (account principal) (id uint))
    (let
        (
            ;; Get the last name ID for the account.
            (last-owner-name (map-get? owners-last-name account)) 
            ;; Get the current primary name for the account.
            (current-primary-name (map-get? primary-name account))
        )
        ;; If there is a last name for the account, link the new name to the end of the list.
        (match last-owner-name last 
            (begin
                ;; Set the new ID as the next name of the last name.
                (map-set next-name-in-list last id)
                ;; Set the last name as the previous name of the new ID.
                (map-set previous-name-in-list id last)
            )
            ;; If there is no last name, it means this is the first name for the account.
            true
        )
        ;; If the principal does not have a primary name, set the new name as the primary name.
        (match current-primary-name 
            primary 
            ;; If there is already a primary name, do nothing.
            true 
            ;; If there is no primary name, set the new name as the primary name.
            (map-set primary-name account id)
        )
        ;; Update the balance map to increase the balance by 1.
        (map-set owner-bns-balance account (+ (get-balance account) u1))
        ;; Update the last name map to set the new name as the last name.
        (map-set owners-last-name account id)
        ;; Return true indicating successful addition.
        true 
    )
)

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

;; Private helper function `is-namespace-available` checks if a namespace is available for registration or other operations.
;; It considers if the namespace has been launched and whether it has expired.
;; @params:
    ;; namespace (buff 20): The namespace to check for availability.
(define-private (is-namespace-available (namespace (buff 20)))
    ;; Check if the namespace exists
    (match (map-get? namespaces namespace) 
        namespace-props
        ;; If it exists
        ;; Check if the namespace has been launched.
        (match (get launched-at namespace-props) 
            launched
            ;; If the namespace is launched, it's considered unavailable if it hasn't expired.
            false
            ;; Check if the namespace is expired by comparing the current block height to the reveal time plus the launchability TTL.
            (> block-height (+ (get revealed-at namespace-props) NAMESPACE-LAUNCHABILITY-TTL))
        )
        ;; If the namespace doesn't exist in the map, it's considered available.
        true
    )
)

;; Private helper function `compute-name-price` calculates the registration price for a name based on its length and character composition.
;; It utilizes a configurable pricing function that can adjust prices based on the name's characteristics.
;; @params:
;;     name (buff 48): The name for which the price is being calculated.
;;     price-function (tuple): A tuple containing the parameters of the pricing function, including:
;;         buckets (list 16 uint): A list defining price multipliers for different name lengths.
;;         base (uint): The base price multiplier.
;;         coeff (uint): A coefficient that adjusts the base price.
;;         nonalpha-discount (uint): A discount applied to names containing non-alphabetic characters.
;;         no-vowel-discount (uint): A discount applied to names lacking vowel characters.
(define-private (compute-name-price (name (buff 48)) (price-function {buckets: (list 16 uint), base: uint, coeff: uint, nonalpha-discount: uint, no-vowel-discount: uint}))
    (let 
        (
            ;; Determine the appropriate exponent based on the name's length.
            ;; This corresponds to a specific bucket in the pricing function.
            ;; The length of the name is used to index into the buckets list, with a maximum index of 15.
            (exponent (get-exp-at-index (get buckets price-function) (min u15 (- (len name) u1)))) 
            ;; Calculate the no-vowel discount.
            ;; If the name has no vowels, apply the no-vowel discount from the price function.
            ;; Otherwise, use 1 indicating no discount.
            (no-vowel-discount (if (not (has-vowels-chars name)) (get no-vowel-discount price-function) u1))
            ;; Calculate the non-alphabetic character discount.
            ;; If the name contains non-alphabetic characters, apply the non-alpha discount from the price function.
            ;; Otherwise, use 1 indicating no discount.
            (nonalpha-discount (if (has-nonalpha-chars name) (get nonalpha-discount price-function) u1))
            (len-name (len name))
        )
        (asserts! (> len-name u0) ERR-NAME-BLANK)
        ;; Compute the final price.
        ;; The base price, adjusted by the coefficient and exponent, is divided by the greater of the two discounts (non-alpha or no-vowel).
        ;; The result is then multiplied by 10 to adjust for unit precision.
        (ok (* (/ (* (get coeff price-function) (pow (get base price-function) exponent)) (max nonalpha-discount no-vowel-discount)) u10))
    )
)

;; SIP-09 compliant function to transfer a token from one owner to another.
;; This function is similar to the 'transfer' function but does not check that the owner is the tx-sender.
;; @param id: the id of the nft being transferred.
;; @param owner: the principal of the current owner of the nft being transferred.
;; @param recipient: the principal of the recipient to whom the nft is being transferred.
(define-private (purchase-transfer (id uint) (owner principal) (recipient principal))
    (let 
        (
            ;; Attempts to retrieve the name and namespace associated with the given NFT ID.
            (name-and-namespace (unwrap! (map-get? index-to-name id) ERR-NO-NAME))
            ;; Extracts the namespace part from the retrieved name-and-namespace tuple.
            (namespace (get namespace name-and-namespace))
            ;; Extracts the name part from the retrieved name-and-namespace tuple.
            (name (get name name-and-namespace))
            ;; Fetches properties of the identified namespace to confirm its existence and retrieve management details.
            (namespace-props (unwrap! (map-get? namespaces namespace) ERR-NAMESPACE-NOT-FOUND))
            ;; Extracts the manager of the namespace.
            (namespace-manager (get namespace-manager namespace-props))
            ;; Retrieves the properties of the name within the namespace.
            (name-props (unwrap! (map-get? name-properties name-and-namespace) ERR-NO-NAME))
            ;; Gets the registered-at value from the name properties.
            (registered-at-value (get registered-at name-props))
            ;; Gets the imported-at value from the name properties.
            (imported-at-value (get imported-at name-props))
            ;; Gets the current owner of the name from the name properties.
            (name-current-owner (get owner name-props))
        )
        ;; Calls the function to update the ownership details, handling necessary updates in the system.
        (transfer-ownership-updates id owner recipient)
        ;; Updates the name properties map with the new information.
        ;; Maintains existing properties but sets the zonefile hash to none for a clean slate and updates the owner to the recipient.
        (map-set name-properties name-and-namespace (merge name-props {zonefile-hash: none, owner: recipient}))
        ;; Executes the NFT transfer from the current owner to the recipient.
        (nft-transfer? BNS-V2 id owner recipient)
    )
)

;; Function to update the renewal-height for all imported names within a namespace
;; This is used in the namespace-ready function to ensure all names are updated immediately when the namespace is launched.
(define-private (update-renewal-height (id uint)) 
    (let 
        (
            ;; Retrieve the name and namespace associated with the given ID.
            (name-namespace (unwrap! (map-get? index-to-name id) ERR-NO-NAME))
            ;; Retrieve the properties of the name within the namespace.
            (name-props (unwrap! (map-get? name-properties name-namespace) ERR-NO-NAME))
            ;; Retrieve the properties of the namespace.
            (namespace-props (unwrap! (map-get? namespaces (get namespace name-namespace)) ERR-NAMESPACE-NOT-FOUND))
        )
        ;; Update the renewal-height field in the name-properties map.
        ;; This is done by merging the existing name properties with the updated renewal-height.
        ;; The renewal-height is set to the sum of the namespace's launched-at time and its lifetime.
        (ok 
            (map-set name-properties name-namespace 
                (merge 
                    name-props 
                    {
                        ;; Calculate the new renewal-height.
                        ;; It is set to the namespace's launched-at time plus the namespace's lifetime.
                        renewal-height: (+ (unwrap! (get launched-at namespace-props) ERR-UNWRAP) (get lifetime namespace-props))
                    }
                )
            )
        ) 
    )
)
