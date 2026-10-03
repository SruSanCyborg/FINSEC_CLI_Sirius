def bound(cur, uid):
    # sirus-ok: SIR-SEC-012
    cur.execute("SELECT * FROM ledger WHERE id = %s", (uid,))

def formatted(cur, uid):
    # sirus-test: SIR-SEC-012
    cur.execute("SELECT * FROM ledger WHERE id = '%s'" % uid)
