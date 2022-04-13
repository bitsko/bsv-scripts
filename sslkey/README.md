# BsvEncKeypair
Creates a bitcoin keypair using bsv.js, encrypts the full pairs and makes a file of the public keys

dependencies: nodejs, bsv, openssl

Usage: ./sslkey \<encrypt or decrypt\> \<number of keys or file name\>                                                                                        
example: ./sslkey encrypt 5                                                                                                                                    
example: ./sslkey decrypt file.name

set a specific number of iterations:
  
example: ./sslkey encrypt 5 iter 12000

example: ./sslkey decrypt thefile iter 12000
