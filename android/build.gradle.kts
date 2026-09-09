allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force all Flutter plugins to compile against SDK 36 so that
// flutter_plugin_android_lifecycle (required by file_picker) is satisfied.
subprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            extensions.findByType(com.android.build.gradle.BaseExtension::class)
                ?.compileSdkVersion(36)
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
