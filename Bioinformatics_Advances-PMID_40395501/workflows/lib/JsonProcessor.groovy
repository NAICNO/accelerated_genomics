import nextflow.Nextflow
import groovy.json.JsonSlurper

class JsonProcessor {
    public static Map<String, Map> processInputJson(String filePath) {
        def jsonSlurper = new JsonSlurper()
        def jsonData = jsonSlurper.parse(new File(filePath))

        // Initialize the maps
        def resultMap = [:]

        jsonData.each { key, value ->
            resultMap[key] = value
        }

        return resultMap
    }
}
