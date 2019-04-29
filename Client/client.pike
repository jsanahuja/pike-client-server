#define PORT 1905
#define HOST "localhost"

import ".";

int main(int argc, array(string) argv){

    Stdio.File socket = Stdio.File();
    if(!socket->connect(HOST,PORT)){
        werror("Couldn't connect to %s:%d: %s\n", HOST, PORT, strerror(socket->errno()));
        return 1;
    }

    string cmd, answer;
    while(1){
        cmd = ask_cmd();
        socket->write(cmd);
        answer = socket->read(1024,1);

        write(answer);
        
        if(cmd == "disconnect"){
            break;
        }
    }
    write("Closing connection...");
    socket->close();
}

string ask_cmd(){
    string answer;
    do{
        write(" > ");
        answer = Stdio.stdin.gets();
    }while(!stringp(answer) || strlen(answer) == 0);
    return answer;
}
