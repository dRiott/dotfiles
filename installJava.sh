echo 'Existing versions of Java:'
/usr/libexec/java_home -V

echo 'Curling Java 17'
curl https://corretto.aws/downloads/latest/amazon-corretto-17-aarch64-macos-jdk.tar.gz

echo 'Extracting Java 17'
tar -xf amazon-corretto-17-aarch64-macos-jdk.tar.gz

echo 'Downloaded JDKs:'
ls -la *.jdk

sudo mv *.jdk /Library/Java/JavaVirtualMachines/

echo 'Checking Java version:'
java -version

