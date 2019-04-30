#define PORT 1905
#define HOST "localhost"
#define MAX_TRIES 10

import ".";

int tries = 0;
bool connected = 0;

int main(int argc, array(string) argv){
    Stdio.File socket;

    signal(signum("SIGINT"), lambda(int sig){
        write("SIGNAL CAUGHT: "+ signame(sig) + "\n");
        if(connected){
            socket->write("disconnect");
            socket->close();
        }
        exit(1);
    });
    
    socket = Stdio.File();
    while(!socket->connect(HOST,PORT)){
        tries++;
        if(tries >= MAX_TRIES){
            werror("Couldn't connect to %s:%d after %d tries. Aborting...", HOST, PORT, tries);
            return 1;
        }else{
            werror("Couldn't connect to %s:%d. Retrying... (attempt %d)\n", HOST, PORT, tries);
            delay(3);
        }
    }
    write("Successfully connected to %s:%d after %d wrong attempts.\n", HOST, PORT, tries);
    connected = true;
    service_worker(socket);
}

void service_worker(Stdio.File socket){
    string cmd;
    mixed error;

    do{
        error = catch{
            cmd = ask_cmd(socket);
            write(socket->read(1024,1));

            if(cmd == "disconnect"){
                connected = false;
            }
        };
    }while(!error && connected);

    if(error){
        write("Server unexpectedly closed the connection. Closing connection.\n");
    }else{        
        write("Closing connection...\n");
    }
    socket->close();
}

string ask_cmd(Stdio.File socket){
    string cmd;
    do{
        write(" > ");
        cmd = Stdio.stdin.gets();
    }while(!stringp(cmd) || strlen(cmd) == 0);
    socket->write(cmd);
    return cmd;
}
