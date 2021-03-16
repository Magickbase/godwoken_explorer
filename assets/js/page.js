import socket from './socket'

// let homeChannel = socket.channel("home:refresh", {})
// homeChannel.join()
//   .receive("ok", (messages) => console.log("catching up", messages) )
// homeChannel.on('refresh', test_msg)

// function test_msg(msg) {
//   console.log(msg.block_list)
//   console.log(msg.tx_list)
//   console.log(msg.statistic)
// }

// let blocksChannel = socket.channel("blocks:20", {})
// blocksChannel.join()
//   .receive("ok", (messages) => console.log("catching up", messages) )
//   .receive("error", ({ reason }) => console.log("failed join", reason))
// blocksChannel.on('refresh', msg => console.log(msg))

// let txChannel = socket.channel("transactions:0x3bd26903a0c8c418d1fba9be7eb13d088b8e68dc1f1d34941c8916246532cccf", {})
// txChannel.join()
//   .receive("ok", (messages) => console.log("catching up", messages) )
//   .receive("error", ({ reason }) => console.log("failed join", reason))
// txChannel.on('refresh', msg => console.log(msg))

// let accountTransactionsChannel = socket.channel("account_transactions:2", {})
// accountTransactionsChannel.join()
//   .receive("ok", (messages) => console.log("catching up", messages) )
//   .receive("error", ({ reason }) => console.log("failed join", reason))
// accountTransactionsChannel.on('refresh', msg => console.log(msg))

// let accountsChannel = socket.channel("accounts:2", {})
// accountsChannel.join()
//   .receive("ok", (messages) => console.log("catching up", messages) )
//   .receive("error", ({ reason }) => console.log("failed join", reason))
// accountsChannel.on('refresh', msg => console.log(msg))
