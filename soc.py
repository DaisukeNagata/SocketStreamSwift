import socket
import threading

HOST = 'localhost'
PORT = 8000
clients = []

def server_start():

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((HOST, PORT))
    sock.listen(5)
    
    while True:
        
        try:
            con, address = sock.accept()
            clients.append((con, address))
        
            handle_thread = threading.Thread(target=handler,
                                         args=(con, address),
                                         daemon=True)
            handle_thread.start()
        
            data = con.recv(4096)
        except ConnectionResetError:
            con.close()
            clients.remove((con, address))
            break
        else:
            
            print(data.decode("utf-8"))
            for c in clients:
                c[0].sendto(data, c[1])
def handler(con, address):
    """クライアントからデータを受信する"""
    
    while True:
        try:
            data = con.recv(4096)
        except ConnectionResetError:
            clients.remove((con, address))
            remove_conection(con, address)
            break
        else:
            if not data:
                clients.remove((con, address))
                remove_conection(con, address)
                break
            else:
                print("[メッセージ]{} - {}".format(address, data.decode("utf-8")))
                for c in clients:
                    c[0].sendto(data, c[1])

if __name__ == "__main__":
    server_start()
