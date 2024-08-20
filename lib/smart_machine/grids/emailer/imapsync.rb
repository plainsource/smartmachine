# TODO: Add imapsync feature to emailer.
# https://imapsync.lamiral.info
# https://hub.docker.com/r/gilleslamiral/imapsync/
# docker run --rm --network=networkone gilleslamiral/imapsync imapsync --host1 <hostname> --user1 <email> --password1 <password> --host2 <hostname> --user2 <email> --password2 <password> --addheader --useheader Message-Id
# Add the following options to delete messages and then their respective folders on the host1 server.
# --delete1 --delete1emptyfolders --noexpungeaftereach
# Display Message to User: For Specific IMAP Server Tips go to https://imapsync.lamiral.info/#doc
