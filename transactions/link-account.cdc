#allowAccountLinking

import FungibleToken from "../contracts/utility/FungibleToken.cdc"
import FlowToken from "../contracts/utility/FlowToken.cdc"
import MetadataViews from "../contracts/utility/MetadataViews.cdc"

import HybridCustody from "../contracts/utility/HybridCustody.cdc"
import CapabilityFactory from "../contracts/utility/CapabilityFactory.cdc"
import CapabilityFilter from "../contracts/utility/CapabilityFilter.cdc"

/// Links child account to the parent account.
/// Parent account gets capabilities of managing Swirl tokens and NFTs.
transaction(
    pubKey: String,
    factoryAddress: Address,
    filterAddress: Address
) {

    prepare(child: AuthAccount, parent: AuthAccount) {
        /* --- Link the AuthAccount Capability --- */
        //
        var acctCap = child.linkAccount(HybridCustody.LinkedAccountPrivatePath)
            ?? panic("problem linking account Capability for new account")

        // Create a OwnedAccount & link Capabilities
        let ownedAccount <- HybridCustody.createOwnedAccount(acct: acctCap)
        child.save(<-ownedAccount, to: HybridCustody.OwnedAccountStoragePath)
        child
            .link<&HybridCustody.OwnedAccount{HybridCustody.BorrowableAccount, HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(
                HybridCustody.OwnedAccountPrivatePath,
                target: HybridCustody.OwnedAccountStoragePath
            )
        child
            .link<&HybridCustody.OwnedAccount{HybridCustody.OwnedAccountPublic, MetadataViews.Resolver}>(
                HybridCustody.OwnedAccountPublicPath,
                target: HybridCustody.OwnedAccountStoragePath
            )

        // Get a reference to the OwnedAccount resource
        let owned = child.borrow<&HybridCustody.OwnedAccount>(from: HybridCustody.OwnedAccountStoragePath)!

        // Get the CapabilityFactory.Manager Capability
        let factory = getAccount(factoryAddress)
            .getCapability<&CapabilityFactory.Manager{CapabilityFactory.Getter}>(
                CapabilityFactory.PublicPath
            )
        assert(factory.check(), message: "factory address is not configured properly")

        // Get the CapabilityFilter.Filter Capability
        let filter = getAccount(filterAddress).getCapability<&{CapabilityFilter.Filter}>(CapabilityFilter.PublicPath)
        assert(filter.check(), message: "capability filter is not configured properly")

        // Configure access for the delegatee parent account
        owned.publishToParent(parentAddress: parent.address, factory: factory, filter: filter)

        /* --- Add delegation to parent account --- */
        //
        // Configure HybridCustody.Manager if needed
        if parent.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath) == nil {
            let m <- HybridCustody.createManager(filter: filter)
            parent.save(<- m, to: HybridCustody.ManagerStoragePath)
        }

        // Link Capabilities
        parent.unlink(HybridCustody.ManagerPublicPath)
        parent.unlink(HybridCustody.ManagerPrivatePath)
        parent.link<&HybridCustody.Manager{HybridCustody.ManagerPrivate, HybridCustody.ManagerPublic}>(
            HybridCustody.ManagerPrivatePath,
            target: HybridCustody.ManagerStoragePath
        )
        parent.link<&HybridCustody.Manager{HybridCustody.ManagerPublic}>(
            HybridCustody.ManagerPublicPath,
            target: HybridCustody.ManagerStoragePath
        )

        // Claim the ChildAccount Capability
        let inboxName = HybridCustody.getChildAccountIdentifier(parent.address)
        let cap = parent
            .inbox
            .claim<&HybridCustody.ChildAccount{HybridCustody.AccountPrivate, HybridCustody.AccountPublic, MetadataViews.Resolver}>(
                inboxName,
                provider: child.address
            ) ?? panic("child account cap not found")

        // Get a reference to the Manager and add the account
        let managerRef = parent.borrow<&HybridCustody.Manager>(from: HybridCustody.ManagerStoragePath)
            ?? panic("manager no found")
        managerRef.addAccount(cap: cap)
    }
}
