import SwirlMoment from "../contracts/SwirlMoment.cdc"

/// Retrieve the SwirlNametag.Profile from the given address.
/// If nametag doesn't exist on the address, it returns nil.
pub fun main(address: Address, keyIndex: Int, lat: Fix64, lng: Fix64): String {
    let pol = SwirlMoment.ProofOfLocation(
        address: getAccount(address),
        location: SwirlMoment.Coordinate(lat: lat, lng: lng),
        nonce: SwirlMoment.nextNonceForProofOfLocation,
        keyIndex: keyIndex,
        signature: "<unused-not-yet>"
    )
    return String.fromUTF8(pol.signedData())!
}
