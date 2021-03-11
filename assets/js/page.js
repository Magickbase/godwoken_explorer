import socket from './socket'

let blocksChannel = socket.channel("home:refresh", {})
blocksChannel.join()
  .receive("ok", (messages) => console.log("catching up", messages) )
blocksChannel.on('refresh', test_msg)

function test_msg(msg) {
  console.log(msg.block_list)
  console.log(msg.tx_list)
  console.log(msg.statistic)
}

function createMenuItem(name) {
    let li = document.createElement('li');
    li.textContent = name;
    return li;
}
