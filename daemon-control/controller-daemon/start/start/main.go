package main

import (
	"github.com/knitzsche/test-controller-daemons/snapdapi"
	"github.com/snapcore/snapd/client"
	"fmt"
)

func main() {

	snap := snapdapi.NewClientAdapter()
	startOpts := client.StartOptions{}
	startOpts.Enable = false
	startMe := make([]string, 1)
	startMe[0] = "test-controller-daemons.controlled-1"
	ID, err2:= snap.Start(startMe, startOpts)
	if err2 != nil{
		fmt.Println(err2)
	} else {
		fmt.Printf("Change ID :%s\n", ID)
	}
}
