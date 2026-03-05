package main

import (
	"os"
	"syscall"

  "github.com/11notes/go-eleven"
	"golang.org/x/crypto/bcrypt"
)

const ADGUARD_CONFIG string = "/adguard/etc/config.yaml"
const ADGUARD_DEFAULT_PASSWORD string = "$2b$12$xzIFiVMrq2jv5NH5pNNQSuEK84FDNI4PoiJbKIhZqUe1Ld/v1BI9W"
const APP_BIN = "/usr/local/bin/AdGuardHome"
const APP_CONFIG_ENV = "ADGUARD_CONFIG"

func main(){
	// write env to file if set
	eleven.Container.EnvToFile(APP_CONFIG_ENV, ADGUARD_CONFIG)

	// check if using default config, if yes, replace default password with random one and print to log
  if ok, _ := eleven.Util.FileContains(ADGUARD_CONFIG, ADGUARD_DEFAULT_PASSWORD); ok {
		password := eleven.Util.Password()
		bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
		if err != nil {
			eleven.LogFatal("could not set a new default password: %s", err)
		}
		replaced, err := eleven.Util.FileReplaceStrings(ADGUARD_CONFIG, map[string]any{ADGUARD_DEFAULT_PASSWORD:string(bytes)})
		if err != nil {
			eleven.LogFatal("could not set a new default password: %s", err)
		}
		if replaced {
			eleven.Log("INF", "password for account admin: %s", password)
		}else{
			eleven.LogFatal("could not set a new default password, because it could not be found, please check your config %s", ADGUARD_CONFIG)
		}
	}

	// start adguard and replace process with it
	if err := syscall.Exec(APP_BIN, []string{"AdGuardHome", "-c", "/adguard/etc/config.yaml", "--pidfile", "/adguard/run/adguard.pid", "--work-dir", "/adguard/var", "--no-check-update"}, os.Environ()); err != nil {
		os.Exit(1)
	}
}