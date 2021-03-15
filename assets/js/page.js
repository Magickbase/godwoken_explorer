import socket from './socket'

let homeChannel = socket.channel("home:refresh", {})
homeChannel.join()
  .receive("ok", (messages) => console.log("catching up", messages) )
homeChannel.on('refresh', test_msg)

function test_msg(msg) {
  console.log(msg.block_list)
  console.log(msg.tx_list)
  console.log(msg.statistic)
}

let blocksChannel = socket.channel("blocks:2320", {})
blocksChannel.join()
  .receive("ok", ({messages}) => console.log("catching up", messages) )
  .receive("error", ({ reason }) => console.log("failed join", reason))
blocksChannel.on('update_l1_block', msg => console.log(msg))
blocksChannel.on('update_status', msg => console.log(msg))