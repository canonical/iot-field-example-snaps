package main

import (
	"github.com/knitzsche/test-controller-daemons/snapdapi"
	"github.com/snapcore/snapd/client"

	"fmt"
	"time"
)

func main() {
	snapDaemon1 := "test-controller-daemons.controlled-1"
	snapDaemon2 := "test-controlled-daemons.controlled-1"
	for { // loop forever
		time.Sleep(20 * time.Second)
		snap := snapdapi.NewClientAdapter()
		startOpts := client.StartOptions{}
		startOpts.Enable = false
		startMe := make([]string, 1)
		//start first daemon
		fmt.Printf("About to start %s\n", snapDaemon1)
		startMe[0] = snapDaemon1
		ID, err2:= snap.Start(startMe, startOpts)
		if err2 != nil{
			fmt.Println(err2)
		} else {
			fmt.Printf("Change ID :%s\n", ID)
		}
		//start second daemon
		fmt.Printf("About to start %s\n", snapDaemon1)
		startMe[0] = snapDaemon2
		ID, err2 = snap.Start(startMe, startOpts)
		if err2 != nil{
			fmt.Println(err2)
		} else {
			fmt.Printf("Change ID :%s\n", ID)
		}
	}
}
