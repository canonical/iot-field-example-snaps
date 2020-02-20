package main

import (
	"github.com/knitzsche/test-controller-daemons/snapdapi"
	"github.com/snapcore/snapd/client"

	"fmt"
	"time"
)

func main() {
	snapDaemon := "test-controlled-daemons.controlled-1"
	for { // loop forever
		time.Sleep(20 * time.Second)
		fmt.Println("About to stop %s", snapDaemon) 
		snap := snapdapi.NewClientAdapter()
		startOpts := client.StartOptions{}
		startOpts.Enable = false
		startMe := make([]string, 1)
		startMe[0] = snapDaemon
		ID, err2:= snap.Start(startMe, startOpts)
		if err2 != nil{
			fmt.Println(err2)
		} else {
			fmt.Printf("Change ID :%s\n", ID)
		}
	}
}
