#define PORT 1905
#define HOST "localhost"

import ".";

Stdio.Port server;

int main(int argc, array(string) argv){
   server = Stdio.Port();

   if(!server->bind(PORT, accept_connection, HOST)){
      werror("Couldn't bind a tcp server on port %s:%d: %s\n", HOST, PORT, strerror(server->errno()));
      return 1;
   }

   return - 1;
}

void accept_connection(){
   Stdio.File connection = server->accept();
   if(!connection) return;

   write("Someone is connecting from "+ server->query_address() +"\n");

   string cmd;
   array(string) split;
   while(1){
      cmd = ask_cmd(connection);
      split = cmd / " ";

      write("Command: '" + cmd + "'\n");
      switch(split[0]){
         case "hello":
            connection->write("Hey, welcome!\n");
            break;
         case "msg":
            split[0] = "";
            write("MSG:"+ split * " ");
            connection->write("Message received\n");
            break;
         case "disconnect":
            connection->write("Disconnecting...\n");
            write("Closing connection...\n");
            connection->close();
            return;
            break;
         default:
            connection->write("Unknown command: " + split[0] + "\n");
            break;
      }
   }
   connection->close();
}

string ask_cmd(Stdio.File socket){
   string cmd;
   do{
      cmd = socket->read(1024,1);
    }while(!stringp(cmd) || strlen(cmd) == 0);
    return cmd;
}