from neo4j import GraphDatabase

class GraphClass():

    def __init__(self, uri="bolt://localhost:7687", user="neo4j", password="butt"):
        self._driver = GraphDatabase.driver(uri, auth=(user, password))

    def close(self):
        self._driver.close()

    def run(self, message, *args, **kwargs):
        with self._driver.session() as session:
            return session.run(message, *args, **kwargs)

    def print_greeting(self, message):
        with self._driver.session() as session:
            greeting = session.write_transaction(self._create_and_return_greeting, message)
            print(greeting)

    def create_user(self, id):
        self.run("MERGE (a:User {id: $id})", id=id)

    def get_user(self, id):
        self.run("MATCH (a:User {id: $id})", id=id)

    def create_follow(self, user, follower):
        self.run("MERGE (a:User {id: $user}) MERGE (b:User {id: $follower}) MERGE (b)-[r:FOLLOWS]->(a)", user=user, follower=follower)

    def parse_follow(self, line):
        x,y = line.strip().split('\t')
        self.create_follow(int(x), int(y))

    def parse_file(self, filename):
        with open(filename, "r") as file:
            with self._driver.session() as session:
                k = 1
                tx = session.begin_transaction()
                for line in file:
                    x,y = line.strip().split('\t')
                    tx.run("MERGE (a:User {id: $user}) MERGE (b:User {id: $follower}) MERGE (b)-[r:FOLLOWS]->(a)", user=int(x), follower=int(y))
                    k += 1
                    if not (k%1000):
                        tx.commit()
                        tx = session.begin_transaction()
                    if not (k%100000):
                        print(k)
                tx.commit()
                print(k)



    @staticmethod
    def _create_and_return_greeting(tx, message):
        result = tx.run("CREATE (a:Greeting) "
                        "SET a.message = $message "
                        "RETURN a.message + ', from node ' + id(a)", message=message)
        return result.single()[0]
