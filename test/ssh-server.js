/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs');
const path = require('path');
const ssh2 = require('ssh2');
const {exec} = require('child_process');
const {Server, utils} = ssh2;

const pubKey = utils.genPublicKey(
  utils.parseKey(
    fs.readFileSync(
      path.join(__dirname, 'id_rsa.pub')
    )
  )
);

const server = new Server({
  privateKey: fs.readFileSync(
    path.join(__dirname, 'id_rsa')
  )
}
, function(client) {
  console.log('Client connected!');

  return client
  .on('authentication', ctx => ctx.accept())
  .on('ready', function() {
    console.log('Client authenticated!');
    return client.on('session', function(accept, reject) {
      const session = accept();
      return session.once('exec', function(accept, reject, info) {
        console.log(`Client wants to execute: ${info.command}`);
        const stream = accept();
        const child = exec(info.command);
        child.stdout.pipe(stream);
        child.stderr.pipe(stream.stderr);
        return stream.exit(0);
      });
    });
}).on('end', () => console.log('Client disconnected'));
});

server.listen(2222, '127.0.0.1', function() { return console.log(`Listening on port ${this.address().port}`); });
