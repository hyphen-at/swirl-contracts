import SwirlMoment from "../contracts/SwirlMoment.cdc"

/// Evaluate signature message (JSON payload) of Proof-of-Meeting.
/// Of course it can be constructed on off-chain, but using this query is recommended because
/// the payload might change in the future.
pub fun main(address: Address, keyIndex: Int, lat: Fix64, lng: Fix64): String {
    let pol = SwirlMoment.ProofOfMeeting(
        address: getAccount(address),
        location: SwirlMoment.Coordinate(lat: lat, lng: lng),
        nonce: SwirlMoment.nextNonceForProofOfMeeting,
        keyIndex: keyIndex,
        signature: "<unused-not-yet>" // we don't validate here, so it's ok to put dummy
    )
    return String.fromUTF8(pol.signedData())!
}
