import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import { List, Purchase } from "../generated/NFTMarket/NFTMarket"

export function createListEvent(
  seller: Address,
  nftAddr: Address,
  tokenId: BigInt,
  price: BigInt
): List {
  let listEvent = changetype<List>(newMockEvent())

  listEvent.parameters = new Array()

  listEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  listEvent.parameters.push(
    new ethereum.EventParam("nftAddr", ethereum.Value.fromAddress(nftAddr))
  )
  listEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  listEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return listEvent
}

export function createPurchaseEvent(
  buyer: Address,
  nftAddr: Address,
  tokenId: BigInt,
  price: BigInt
): Purchase {
  let purchaseEvent = changetype<Purchase>(newMockEvent())

  purchaseEvent.parameters = new Array()

  purchaseEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  purchaseEvent.parameters.push(
    new ethereum.EventParam("nftAddr", ethereum.Value.fromAddress(nftAddr))
  )
  purchaseEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  purchaseEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return purchaseEvent
}
