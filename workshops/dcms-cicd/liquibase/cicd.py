#!/usr/bin/env python3
import argparse, logging, subprocess, os, sys, glob

# Logging Default
logging.basicConfig(format='[%(asctime)s] %(levelname)8s: %(message)s', 
                    datefmt='%Y-%b-%d %H:%M:%S', level=logging.INFO)
log = logging.getLogger(__name__)

""" Globals
"""
tns_admin = '/var/lib/jenkins'

""" Functions
"""
def run_sqlcl(schema, password, service, cmd, resolution, conn_file, run_as):
    lb_env = os.environ.copy()
    lb_env['password']  = password
    lb_env['schema']    = schema

    if resolution == 'wallet':
        wallet = f'set cloudconfig {conn_file}'
    else:
        lb_env['TNS_ADMIN'] = tns_admin #<-Global

    # Keep password off the command line/shell history
    sql_cmd = f'''
        {wallet}
        conn {run_as}/{password}@{service}_high
        {cmd}
    '''

    log.debug(f'Running: {sql_cmd}')
    result = subprocess.run(['/workspace/sqlcl/bin/sql', '/nolog'], universal_newlines=True, input=f'{sql_cmd}', env=lb_env,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    exit_status = 0
    error_matches = ['Error Message','ORA-','SQL Error','Validation Failed']
    result_list = result.stdout.splitlines();
    for line in filter(None, result_list):
        log.info(line)
        if any(x in line for x in error_matches):
            exit_status = 1
    if result.returncode or exit_status:
        log.fatal('Exiting...')
        sys.exit(1)

    log.info('SQLcl command successful')


def deploy(password, resolution, conn_file, args):
    log.info('Running controller.admin.xml')
    cmd = 'lb update -changelog controller.admin.xml;'
    run_sqlcl(args.dbUser, password, args.dbName, cmd, resolution, conn_file, 'ADMIN')

    log.info('Running controller.xml')
    cmd = 'lb update -changelog controller.xml;'
    run_sqlcl(args.dbUser, password, args.dbName, cmd, resolution, conn_file, args.dbUser)

    if os.path.exists('controller.data.xml'):
        log.info('Running controller.data.xml')
        cmd = 'lb update -changelog controller.data.xml;'
        run_sqlcl(args.dbUser, password, args.dbName, cmd, resolution, conn_file, args.dbUser)


def generate(password, resolution, conn_file, args):
    cmd = 'lb genschema -grants -split'
    run_sqlcl(args.dbUser, password, args.dbName, cmd, resolution, conn_file, args.dbUser)

    # To avoid false changes impacting version control, replace schema names
    # You do you, here:
    log.info('Cleaning up genschema...')
    for filepath in glob.iglob('./**/*.xml', recursive=True):
        log.info(f'Processing {filepath}')
        with open(filepath) as file:
            s = file.read()
        s = s.replace(args.dbUser, '${schema}')
        with open(filepath, "w") as file:
            file.write(s)


def destroy(password, resolution, conn_file, args):
    cmd = 'lb rollback -changelog user.xml -count 999;'
    run_sqlcl(args.dbUser, password, args.dbName, cmd, resolution, conn_file, 'ADMIN')

""" INIT
"""
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='CI/CD Liquibase Helper')
    parent_parser = argparse.ArgumentParser(add_help=False)
    parent_parser.add_argument('--dbName',   required=True,  action='store',      help='Database Name')
    parent_parser.add_argument('--dbUser',   required=True,  action='store',      help='Schema User')
    parent_parser.add_argument('--dbPass',   required=False, action='store',      help='ADMIN Password')
    parent_parser.add_argument('--dbWallet', required=False, action='store',      help='Schema User')
    parent_parser.add_argument('--debug',    required=False, action='store_true', help='Enable Debug')

    subparsers = parser.add_subparsers(help='Actions')
    # Deploy
    deploy_parser = subparsers.add_parser('deploy', parents=[parent_parser],
        help='Deploy'
    )
    deploy_parser.set_defaults(func=deploy,action='deploy')

    # Generate
    generate_parser = subparsers.add_parser('generate', parents=[parent_parser],
        help='Generate Changelogs'
    )
    generate_parser.set_defaults(func=generate,action='generate')

    # Destroy
    destroy_parser = subparsers.add_parser('destroy', parents=[parent_parser],
        help='Destroy'
    )
    destroy_parser.set_defaults(func=destroy,action='destroy')

    if len(sys.argv[1:])==0:
        parser.print_help()
        parser.exit()

    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
        logging.debug("Debugging Enabled")

    logging.debug('Arguments: {}'.format(args))

    """ MAIN
    """
    if args.dbPass:
        password = args.dbPass
    else:
        try:
            f = open(".secret", "r")
            password = f.readline().split()[-1]
        except:
            log.fatal('Database password required')
            sys.exit(1)

    resolution = 'wallet' # Default
    conn_file  = None
    if args.dbWallet:
        conn_file     = args.dbWallet
    else:
        if os.path.exists(f'{tns_admin}/adb_wallet.zip'):
            conn_file = f'{tns_admin}/adb_wallet.zip'
        elif os.path.exists(f'{tns_admin}/tnsnames.ora'):
            resolution   = 'tnsnames'
            conn_file    = '{tns_admin}/tnsnames.ora'

    logging.info(f'{resolution} resolution with {conn_file}')
    args.func(password, resolution, conn_file,  args)
    sys.exit(0)
