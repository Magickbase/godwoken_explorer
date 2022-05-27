# WithdrawReuest
## List by eth address
```
GET /withdrawal_requests
```

### Parameters
|Name|Type|In|Description|
|---|---|---|---|
|eth_address|string|query|user eth address|
|page|integer|query|default is 1|

### Code samples

```console
https://api.staging.gwscan.com/api/withdrawal_requests?eth_address=0x3657e473b62a5f3265f5a5a8bf640351199e2f3f
```

### Response

```
Status: 200 OK
```

```json
{
  data: [
    {
      attributes: {
        account_script_hash: "0xb6f642bafd4210557c25cbb0ced95fcb45c59071c41015ab5335f413b68c9ace",
        block_hash: "0xa5231502709ffdf1dbef2047c74f547fac159821a0ff4eefddd6286e0fbb7851",
        block_number: 248539,
        ckb: "265",
        nonce: 12526,
        owner_lock_hash: "0xf539266ebeebbc2084071b18e2659c6a46a21842ba60ec1e4f7787545be0c949",
        payment_lock_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        sell_ckb: "100",
        sell_value: "0",
        sudt_script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        udt_id: 1,
        value: "0"
      },
      id: "92938",
      relationships: {
        udt: {
          data: {
            id: "1",
            type: "udt"
          }
        }
      },
      type: "withdrawal_request"
    },
  ],
  included: [
    {
      attributes: {
        decimal: 8,
        description: null,
        holder_count: 23388,
        icon: null,
        id: 1,
        name: "Nervos Token",
        official_site: null,
        script_hash: "0x0000000000000000000000000000000000000000000000000000000000000000",
        eth_address: null,
        supply: "240000000000",
        symbol: "CKB",
        transfer_count: 0,
        type: "bridge",
        type_script: {
          args: "",
          code_hash: "",
          hash_type: ""
        },
        value: null
      },
      id: "1",
      relationships: { },
      type: "udt"
    }
  ],
  meta: {
    current_page: 1,
    total_page: 78
    }
}
