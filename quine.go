// a quine in go (134 bytes)
package main;import "fmt";func main(){s:="package main;import %cfmt%c;func main(){s:=%q;fmt.Printf(s,34,34,s)}";fmt.Printf(s,34,34,s)}