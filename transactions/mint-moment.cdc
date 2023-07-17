import NonFungibleToken from "../contracts/utility/NonFungibleToken.cdc"
import MetadataViews from "../contracts/utility/MetadataViews.cdc"
import SwirlMoment from "../contracts/SwirlMoment.cdc"

transaction(address: [Address], lat: [Fix64], lng: [Fix64], nonce: [UInt64], keyIndex: [Int], signature: [String]) {
    let proofs: [SwirlMoment.ProofOfMeeting]

    prepare(signer: AuthAccount) {
        self.proofs = []

        for i, addr in address {
            let proof = SwirlMoment.ProofOfMeeting(
                account: getAccount(addr),
                location: SwirlMoment.Coordinate(lat[i], lng[i]),
                nonce: nonce[i],
                keyIndex: keyIndex[i],
                signature: signature[i]
            )
            self.proofs.append(proof)
        }
    }

    execute {
        SwirlMoment.mint(proofs: self.proofs)
    }
}
