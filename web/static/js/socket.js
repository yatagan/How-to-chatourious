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
let renderLine = (text) => {
  let template = document.createElement("div");
  template.innerHTML = `${text}<br>`

  chatMessages.appendChild(template);
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

let renderMessage = (message) => {
  let template = document.createElement("div");
  let date = message.inserted_at ?
    moment.tz(message.inserted_at, "Etc/UTC").tz(moment.tz.guess()) : moment.default();

  renderLine(`<i>[${date.format('HH:mm:ss')}]</i> <b>&lt;${message.user}&gt;</b> ${message.text}`);
}

let renderEvent = (username, action) => {
  renderLine(`*** ${username} ${action} the chatroom ***`);
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
  data.last_messages.forEach((message) => {
    if (message.type == "message")
      renderMessage(message);
    else if (message.type == "event")
      renderEvent(message.user, message.text);
  });
});

channel.on('user:joined', user => {
  renderEvent(user.name, "joined");
});

channel.on('user:left', user => {
  renderEvent(user.name, "left");
});

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
