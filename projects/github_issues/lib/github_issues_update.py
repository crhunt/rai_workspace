#!/home/cassi/anaconda3/bin/python3

from railib import api, config, show
from datetime import date, timedelta
import json, time, sys, os, argparse
from urllib.request import HTTPError

ghparser = argparse.ArgumentParser(description="Update github issues database.")
ghparser.add_argument("--delete", dest='delete', action='store_true', \
                      help="Delete the database first.")
ghparser.set_defaults(delete=False)
args = ghparser.parse_args()

def create_engine(ctx, engine_name):
    print(f"Creating engine {engine_name}...")

    # Check if engine exists
    eng = api.get_engine(ctx, engine_name)
    if len(eng) > 0:
        print(f"    Engine {engine_name} already exists. Status: {eng['state']}")
        return

    size=api.EngineSize.S
    try:
        response = api.create_engine(ctx, engine_name, size)
        print(json.dumps(response, indent=2))
        #print("skip")
    except HTTPError as e:
        if e.code == 409:
            print(f"    ERROR 409: Engine {engine_name} already exists.")
        show.http_error(e)

def delete_engine(ctx, engine_name):
    print(f"Deleting engine {engine_name}...")

    eng = api.get_engine(ctx, engine_name)
    if len(eng) == 0:
        print(f"    No engine {engine_name} to delete.")
        return
    if eng['state'] == "DELETED":
        print(f"    Engine {engine_name} already deleted.")
    try:
        rsp = api.delete_engine(ctx, engine_name)
        print(f"Deleted engine {engine_name}")
    except HTTPError as e:
        if e.code == 404:
            print(f"    ERROR 404: No engine {engine_name} to delete.")
        else:
            show.http_error(e)

def confirm_provision(ctx, engine_name):
    print(f"Confirming status of {engine_name}...")
    provisioned = False
    attempts = 0
    while not provisioned:
        # PROVISIONED
        state = api.get_engine(ctx, engine_name)["state"]
        print(f"    Engine {engine_name} is {state}.")
        if state == "PROVISIONED": 
            provisioned = True
        attempts += 1
        if attempts > 5:
            print(f"    Error: Timed out waiting for engine {engine_names} to provision.")
            return False
        if not provisioned: 
            time.sleep(3*60)
    return True

def delete_db(ctx, db_name):
    print(f"Deleting database {db_name}...")

    rsp = api.get_database(ctx, db_name)
    if len(rsp) == 0:
        print(f"    Database not found: {db_name}")
        return
    try:
        rsp = api.delete_database(ctx, db_name)
        print(json.dumps(rsp, indent=2))
    except HTTPError as e:
        show.http_error(e)
    

def connect_db(ctx, db_name, engine_name):
    print(f"Checking status of database {db_name}...")

    # Does the database exist?
    rsp = api.get_database(ctx, db_name)
    overwrite = False
    if len(rsp) == 0:
        print(f"    Creating new database {db_name}")
        try:
            rsp = api.create_database(ctx, db_name, engine_name, overwrite=True)
            #print(json.dumps(rsp, indent=2))
            #print("skip")
        except HTTPError as e:
            show.http_error(e)
            return
    else:
        print(f"    Database found: {db_name}")

def install_model(ctx, db_name, engine_name):

    src_name = "github_issues_schema"
    src_list = api.list_sources(ctx, db_name, engine_name)
    if src_name in src_list:
        print("Schema found in sources:")
        print("    " + ", ".join(src_list))
        return
    
    # Get all source files as single source
    print(f"Installing source {src_name}")
    deps = [ "data-format", "issue-schema", "label-schema", "user-schema", 
             "repo-schema", "milestone-schema", "custom-reports" ]
    pwd = os.path.dirname(os.getcwd())
    q = ""
    for dep in deps:
        print(f"    Adding: {pwd}/src/{dep}.rel")
        with open(f"{pwd}/src/{dep}.rel", mode='r') as f:
            data = f.read()
        
        q += f"""
            /* - Start of linked file: {dep} - */
            {data}
            /* ----- End of linked file: {dep} ----- */
            """
    # Install source
    print("    Installing...")
    api.install_source(ctx, db_name, engine_name, {src_name : q})

    # Install integrity constraints
    icdep = "integrity-constraints"
    ic_src_name = "github_issues_ics"
    print(f"Installing integrity constraints as source {ic_src_name}")
    with open(f"{pwd}/src/{icdep}.rel", mode='r') as f:
        icq = f.read()
    print(f"    Adding: {pwd}/src/{icdep}.rel")
    print("    Installing...")
    api.install_source(ctx, db_name, engine_name, {ic_src_name : icq})
    src_list = api.list_sources(ctx, db_name, engine_name)
    print("Sources installed: " + ", ".join(src_list))


def load_data(ctx, db_name, engine_name):

    print(f"Loading data to {db_name}...")
    pwd = os.path.dirname(os.getcwd())
    repo = "raicode"
    data_types = ["labels", "milestones","issues"]
    files = {}
    for k in data_types:
        files[f"json_{k}"] = f"{pwd}/data/{repo}-{k}.json"
    files["json_repos"] = f"{pwd}/data/{repo}-repo.json"
    files["json_users"] = f"{pwd}/data/{repo}-user-details.json"

    q = ""
    for relname in files:
        print(f"    Adding: {files[relname]}")
        # Get data as string
        with open(files[relname], mode='r') as f:
            data = f.read()
        # Build rel update query
        q = q + f"""
            def data_config[:{repo}][:{relname}][:data] = {json.dumps(data)}
            def delete[:{relname}][:{repo}](xs...) = {relname}[:{repo}](xs...)
            def insert[:{relname}][:{repo}](xs...) = load_json[ data_config[:{repo}][:{relname}] ](xs...)
            """
    
    try:
        print("    Executing update...")
        rsp = api.query(ctx, db_name, engine_name, q, readonly=False)
    except HTTPError as e:
        show.http_error(e)
        return False
    print("    Update complete.")
    
    print(f"""Executing test query, expect "{repo}" """)
    testq = f"def output = json_repos:{repo}[:[], 1, :name]"
    try:
        rsp = api.query(ctx, db_name, engine_name, testq, readonly=True)
        show.results(rsp)
    except HTTPError as e:
        show.http_error(e)
        return False

    return True

def query_graph(ctx, db_name, engine_name):

    # Execute query
    print("Querying data table...")
    q = "def output = issue_table_row"
    try:
        rsp = api.query(ctx, db_name, engine_name, q, readonly=True)
        #show.results(rsp)
    except HTTPError as e:
        show.http_error(e)
        return
    print("    Query successful.")
    # Create html document
    ncol = len(rsp['output'][0]['columns'])-1 # 2
    html_data = "".join(rsp['output'][0]['columns'][ncol])
    html_file = f"""
        <html>
        <body>
        <table>
        {html_data}
        </table>
        </body>
        </html>
    """

    pwd = os.path.dirname(os.getcwd())
    today = date.today()
    today_str = today.strftime("%Y-%m-%d")
    outfile = f"{pwd}/results/gh-report-{today_str}.html"
    print(f"Saving results to: {outfile}")
    with open(outfile, 'w') as f:
        f.write(html_file)


def main():

    # Set up Managed Connection to the RKGMS
    cfg = config.read()
    ctx = api.Context(**cfg)

    # Make script directory current
    #os.chdir(os.path.dirname(sys.argv[0]))
    script_dir = os.path.dirname(os.path.realpath(__file__))
    os.chdir(script_dir)
    cwd = os.getcwd()
    print(f"\nCWD: {cwd}")

    # Create a new engine
    today = date.today()
    today_str = today.strftime("%Y-%m-%d")
    print(f"Update github issues {today_str}")
    engine_name="github-engine-"+today_str+"-s"
    create_engine(ctx, engine_name)

    # Delete previous engine
    yesterday = (today - timedelta(days = 1))
    yesterday_str = yesterday.strftime("%Y-%m-%d")
    yesterday_engine="github-engine-"+yesterday_str+"-s"
    delete_engine(ctx, yesterday_engine)


    # Pull new data using github api
    cwd = os.getcwd()
    exec(open(cwd+"/pull_github_data.py").read(), globals(), globals())


    # Wait until compute is created
    provisioned = confirm_provision(ctx, engine_name)
    if not provisioned:
        return

    # Set up database
    db_name = "github_issues_continuous"
    # Delete database?
    if args.delete:
        delete_db(ctx, db_name)
    # Connect engine to database
    connect_db(ctx, db_name, engine_name)

    # Update data in database
    st = load_data(ctx, db_name, engine_name)
    if not st:
        print("ERROR loading data.")
        return

    # If new database, install model
    install_model(ctx, db_name, engine_name)

    # Query graph and save output
    query_graph(ctx, db_name, engine_name)

    # Complete
    print("Full github issues update complete.\n")


if __name__ == "__main__":
    main()