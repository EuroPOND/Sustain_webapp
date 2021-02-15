<?php

// reading post and set file names

$wp_user_email = $_POST['email'];
$sex = $_POST['sex'];
$age = $_POST['age'];
$target_dir ='/var/www/html/Data/uploads/';
$target_file = $target_dir . basename($_FILES['fileToUpload']['name']);

if (isset($_FILES["fileToUpload"]) == false)
{
   echo "Please select file to upload!";
   return;
}

// variable to check upload
$uploadOk = 1;

if ($sex == "M") {
$nsex = 0;
} else {
$nsex = 1;
}

//print out settings

echo "Your email is: ",$wp_user_email;
echo "<br>";
echo "Subject sex: ", $sex, ".";
echo "<br>";
echo "Subject age: ", $age, ".";
echo "<br>";
echo "<br>";

// check file name

if (strlen(basename($_FILES['fileToUpload']['name'])) > 0) {
        echo "File name: ", basename($_FILES['fileToUpload']['name']), " (valid name).";
        echo "<br>";
        } else {
        echo "Unable to read File Name!";
        $uploadOk = 0;
}
// check file type

$imageFileType = pathinfo($target_file,PATHINFO_EXTENSION);

if($imageFileType == "nii" or $imageFileType == "nifti" or $imageFileType == "gz" or $imageFileType == "zip") {
        echo "Image type: .", $imageFileType, " (image type ok).";
        echo "<br>";
        } else {
        echo "Image type: .", $imageFileType, " (invalid image type, only nifti are allowed).";
        echo "<br>";
        $uploadOk = 0;
}

// Check file size

if ($_FILES["fileToUpload"]["size"] > 50000000000) {
        echo "File size: ", $_FILES["fileToUpload"]["size"], "kB (your file is too large).";
        echo "<br>";
	echo "<br>";
        $uploadOk = 0;
        } else {
        echo "File size: ", $_FILES["fileToUpload"]["size"], "kB (file size ok).";
        echo "<br>";
	echo "<br>";
}

// Check the value of $uploadOk, upload the file and check upload and launch the script

if ($uploadOk == 0) {
    echo "Sorry, your file was not uploaded.";
// if everything is ok, try to upload file
    } else {
        move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file);
        if (file_exists( $target_file)) {
            echo "The file ", basename( $_FILES["fileToUpload"]["name"]), " has been uploaded, you will be redirected within 10 seconds.";
            echo "<br>";
            // the following lines launch the script sustain.sh where all tha computations are performed (it would be best to launch it using a job scheduler, if available)
            $script_string ="bash sustain.sh ".$_FILES['fileToUpload']['name']." ".$age." ".$nsex." ".$wp_user_email." > log1 2> log2 &";
            shell_exec("$script_string");
        }  else {
            echo "Sorry, there was an error uploading your file, please retry!";
}
}

//redirect to webapp url
header( "refresh:10;url=http://localhost" );

?>
