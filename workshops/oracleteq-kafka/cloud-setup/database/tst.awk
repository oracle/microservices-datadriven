BEGIN { FS=RS; RS=""; ORS="\n" }
{
    delete f

    f["NAME"] = $1
    sub(/[[:space:]]*=.*/,"",f["NAME"])

    for (i=2; i<=NF; i++) {
        n = split($i,tmp,/[ =()]+/)
        for (j=n-2; j>1; j-=2) {
            f[tmp[j]] = tmp[j+1]
        }
    }

    prt()
}

function prt() {
    for (tag in f) {
        print tag "=<" f[tag] ">"
    }
    print "----"
}