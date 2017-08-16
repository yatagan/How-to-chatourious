import {Socket, Presence} from "phoenix"
import * as moment from 'moment-timezone';

let socket = new Socket("/socket", {
  params: {token: window.userToken}})

socket.connect()
let channel = socket.channel("room:" + window.roomId, {})
let message = $('#message-input')
let chatMessages = document.getElementById("chat-messages")
let presences = {}
let onlineUsers = document.getElementById("online-users")

let listUsers = (user) => {
  return {
    user: user
  }
}
let renderUsers = (presences) => {
  onlineUsers.innerHTML = Presence.list(presences, listUsers)
  .map(presence => `
    <li>${presence.user}</li>`).join("")
}
let renderMessage = (message) => {
  let template = document.createElement("div");
  let date = message.inserted_at ?
    moment.tz(message.inserted_at, "Etc/UTC").tz(moment.tz.guess()) : moment.default();
  template.innerHTML = `<i>[${date.format('HH:mm:ss')}]</i> <b>&lt;${message.user}&gt;</b> ${message.text}<br>`

  chatMessages.appendChild(template);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

message.focus();

message.on('keypress', event => {
  if(event.keyCode == 13) {
    channel.push('message:new', {message: message.val()})
    message.val("")
  }
});

channel.on('message:new', payload => {
  renderMessage({user: payload.user, text: payload.message});
});

channel.on('presence_state', state => {
  presences = Presence.syncState(presences, state)
  renderUsers(presences)
});

channel.on('presence_diff', diff => {
  presences = Presence.syncDiff(presences, diff)
  renderUsers(presences)
});

channel.on('last_messages', data => {
  data.last_messages.forEach(renderMessage);
});

channel.on('user:joined', user => {
  renderMessage({user: user.name, text: "joined the chatroom"});
});

channel.on('user:left', user => {
  renderMessage({user: user.name, text: "left the chatroom"});
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
