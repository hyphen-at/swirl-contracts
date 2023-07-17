import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import SwirlMoment from "../contracts/SwirlMoment.cdc"

transaction(id: UInt64) {
    /// Reference that will be used for the owner's collection
    let collectionRef: &SwirlMoment.Collection

    prepare(signer: AuthAccount) {
        // borrow a reference to the owner's collection
        self.collectionRef = signer.borrow<&SwirlMoment.Collection>(from: SwirlMoment.CollectionStoragePath)
            ?? panic("Account does not store an object at the specified path")

    }

    execute {
        self.collectionRef.burn(id: id)
    }

    post {
        !self.collectionRef.getIDs().contains(id): "The NFT with the specified ID should have been deleted"
    }
}
