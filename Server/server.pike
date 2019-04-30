#define PORT 1905
#define HOST "localhost"

import ".";

Stdio.Port server;
int index = 0;
mapping(int:Thread.Thread) threads = ([]);
mapping(int:Stdio.File) connections = ([]);

int main(int argc, array(string) argv){
   signal(signum("SIGINT"), lambda(int sig){
      write("SIGNAL CAUGHT: "+ signame(sig) + "\n");
      mixed error;
      foreach(threads; int id; Thread.Thread thread){
         error = catch{ connections[id]->stat(); };
         if(!error){
            write("CLI:%d:KILL: Closing socket and killing thread...\n", id);
            connections[id]->close();
            thread->kill();
            if(thread->status == Thread.THREAD_RUNNING)
               thread->wait();
         }
      }
      exit(1);
   });


   server = Stdio.Port();

   if(!server->bind(PORT, accept_connection, HOST)){
      werror("Couldn't bind a tcp server on port %s:%d: %s\n", HOST, PORT, strerror(server->errno()));
      return 1;
   }
   return - 1;
}

void accept_connection(){
   //accepting connection
   Stdio.File connection = server->accept();
   if(!connection) return;

   //setting client id
   index++;
   int id = index;
 
   write("CLI:%d:CONNECT: New connection from %s\n", id, server->query_address());

   //creating thread
   Thread.Thread thread = Thread.Thread(service_worker, connection, id);

   //storing the thread reference to kill him if we got a sigint
   threads |= ([ id:thread ]);
   connections |= ([ id:connection ]);
}

void service_worker(Stdio.File connection, int id){
   string command;
   array(string) arguments;
   mixed error;

   do{
      error = catch{
         [command, arguments] = ask_cmd(connection);

         write("CLI:%d:COMMAND: '%s'\n", id, command);
         switch(command){
            case "hello":
               connection->write("Hey, welcome!\n");
               break;
            case "msg":
               write("CLI:%d:MESSAGE: %s\n", id, (arguments * " "));
               connection->write("Message received\n");
               break;
            case "disconnect":
               write("CLI:%d:DISCONNECT: Closing connection with %s\n", id, server->query_address());
               connection->write("Disconnecting...\n");
               connection->close();
               return;
            default:
               write("CLI:%d:WARNING: Unknown command %s\n", id, command);
               connection->write("Unknown command: " + command + "\n");
               break;
         }
      };
      error = catch{ connection->stat(); };
   }while(!error);
   //probably redundant
   write("CLI:%d:ERROR: Closing connection with %s\n", id, server->query_address());
   connection->close();
   return;
}

array(string|array(string)) ask_cmd(Stdio.File socket){
   string cmd;
   do{
      cmd = socket->read(1024,1);
   }while(!stringp(cmd) || strlen(cmd) == 0);

   array(string) split = cmd / " ";
   string command = split[0];
   split[0] = 0;
   return ({command, split});
}

string|void print_r(mixed item, bool|void display){
    string  result = "", 
            type = basetype(item), 
            elements = "";
    switch(type){
        case "function":
            result += "function " + function_name(item);
            break;
        case "program":
            result += "program";
            break;
        case "object":
            foreach(indices(item), mixed index){
                elements += sprintf("\n\t%s => %s", (string) index, print_r(item[index], false));
            }        
            result += sprintf("Object (%s\n)", elements);
            break;
        case "array":
            foreach(item; int key; mixed subitem){
                elements += sprintf("\n\t%d => %s", key, print_r(subitem, false));
            }
            result += sprintf("Array (%s\n)", elements);
            break;
        case "mapping":
            foreach(item; mixed key; mixed subitem){
                elements += sprintf("\n\t%s => %s", print_r(key, false), print_r(subitem, false));
            }
            result += sprintf("Mapping (%s\n)", elements);
            break;
        case "multiset":
            foreach(item; mixed key; mixed subitem){
                elements += sprintf("\n\t%s => %s", print_r(key, false), print_r(subitem, false));
            }
            result += sprintf("Multiset (%s\n)", elements);
            break;
        case "string":
            result += sprintf("\"%s\" (string)", item);
            break;
        default:
            result += sprintf("%s (%s)", (string) item, type);
            break;
    }

    //output
    if(zero_type(display) || display){
        write(result + "\n");
    }else{
        return result;
    }
}