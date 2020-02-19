package snapdapi

import (
	"github.com/snapcore/snapd/asserts"
	"github.com/snapcore/snapd/client"
	"sync"
)

// SnapdClient is a client of the snapd REST API
type SnapdClient interface {
	Snap(name string) (*client.Snap, *client.ResultInfo, error)
	List(names []string, opts *client.ListOptions) ([]*client.Snap, error)
	Install(name string, options *client.SnapOptions) (string, error)
	Refresh(name string, options *client.SnapOptions) (string, error)
	Revert(name string, options *client.SnapOptions) (string, error)
	Remove(name string, options *client.SnapOptions) (string, error)
	Enable(name string, options *client.SnapOptions) (string, error)
	Disable(name string, options *client.SnapOptions) (string, error)
	ServerVersion() (*client.ServerVersion, error)
	Ack(b []byte) error
	Known(assertTypeName string, headers map[string]string) ([]asserts.Assertion, error)
	Conf(name string) (map[string]interface{}, error)
	SetConf(name string, patch map[string]interface{}) (string, error)

	GetEncodedAssertions() ([]byte, error)
	DeviceInfo() (ActionDevice, error)
}

var clientOnce sync.Once
var clientInstance *ClientAdapter

// ClientAdapter adapts our expectations to the snapd client API.
type ClientAdapter struct {
	snapdClient *client.Client
}

// NewClientAdapter creates a new ClientAdapter as a singleton
func NewClientAdapter() *ClientAdapter {
	clientOnce.Do(func() {
		clientInstance = &ClientAdapter{
			snapdClient: client.New(nil),
		}
	})

	return clientInstance
}

// Snap returns the most recently published revision of the snap with the
// provided name.
func (a *ClientAdapter) Snap(name string) (*client.Snap, *client.ResultInfo, error) {
	return a.snapdClient.Snap(name)
}

// List returns the list of all snaps installed on the system
// with names in the given list; if the list is empty, all snaps.
func (a *ClientAdapter) List(names []string, opts *client.ListOptions) ([]*client.Snap, error) {
	return a.snapdClient.List(names, opts)
}
