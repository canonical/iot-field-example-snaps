package main

import (
	"github.com/knitzsche/test-controller-daemons/snapdapi"
	"github.com/snapcore/snapd/client"
	"fmt"
)

func main() {

	snap := snapdapi.NewClientAdapter()
	names := make([]string, 50)
	listoptions := &client.ListOptions{}
	snaps, err:= snap.List(names, listoptions)
	if err != nil{
		fmt.Println(err)
	} else {
		for _,s := range snaps {
			fmt.Printf("Snap:%s, Revision: %s\n", s.Title, s.Revision)
		}
	}
}
