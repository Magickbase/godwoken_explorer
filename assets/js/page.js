import socket from './socket'

let blocksChannel = socket.channel("blocks:new_block", {})
blocksChannel.join()
blocksChannel.on('new_block', test_msg)

function test_msg(msg) {
  console.log(msg),
  document.getElementById("recent-blocks").appendChild(createMenuItem(msg.block))
}

function createMenuItem(name) {
    let li = document.createElement('li');
    li.textContent = name;
    return li;
}
