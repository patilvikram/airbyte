package io.airbyte.config.init;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableMap;
import io.airbyte.commons.io.IOs;
import io.airbyte.commons.json.Jsons;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Iterator;
import java.util.UUID;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;

public class RepositorySeed {
  private static final Options OPTIONS = new Options();
  private static final Option ID_NAME_OPTION = new Option("id", "id-name", true, "field name of the id");
  private static final Option INPUT_PATH_OPTION = new Option("i", "input-path", true, "path to input file");
  private static final Option OUTPUT_PATH_OPTION = new Option("o", "output-path", true, "path to where files will be output");
  static {
    ID_NAME_OPTION.setRequired(true);
    INPUT_PATH_OPTION.setRequired(true);
    OUTPUT_PATH_OPTION.setRequired(true);
    OPTIONS.addOption(ID_NAME_OPTION);
    OPTIONS.addOption(INPUT_PATH_OPTION);
    OPTIONS.addOption(OUTPUT_PATH_OPTION);
  }

  public void run(String idName, Path input, Path output) throws IOException {
    final ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
    final JsonNode jsonNode = mapper.readTree(input.toFile());
    final Iterator<JsonNode> elements = jsonNode.elements();

    while(elements.hasNext()) {
      final JsonNode element = Jsons.clone(elements.next());
      final UUID uuid = UUID.nameUUIDFromBytes(Jsons.serialize(element).getBytes(Charsets.UTF_8));
      ((ObjectNode)element).put(idName, uuid.toString());

      IOs.writeFile(
          output,
          uuid.toString() + ".json",
          element.toPrettyString()); // todo (cgardens) - adds obnoxious space in front of ":".
    }
  }

  public static void run2() throws IOException {
    final Path path = Path.of("/Users/charles/code/airbyte/airbyte-config/init/src/main/resources/config/STANDARD_SOURCE_DEFINITION");
    final ObjectMapper yamlMapper = new ObjectMapper(new YAMLFactory());
    ArrayNode array = new ArrayNode(yamlMapper.getNodeFactory());
    Files.list(path).forEach(file -> {
        final JsonNode deserialize = Jsons.deserialize(IOs.readFile(file));
        array.add(deserialize);
//        final JsonNode jsonNode = mapper.readTree(file.toFile());
    });
    final String s = yamlMapper.writeValueAsString(array);
    IOs.writeFile(Path.of("/tmp/end.yaml"), s);
  }

  private static CommandLine parse(String[] args) {
    final CommandLineParser parser = new DefaultParser();
    final HelpFormatter helpFormatter = new HelpFormatter();

    try {
      return parser.parse(OPTIONS, args);
    } catch (ParseException e) {
      helpFormatter.printHelp("", OPTIONS);
      throw new IllegalArgumentException(e);
    }
  }

  public static void main(String[] args) throws IOException {
    run2();
  }
//  public static void main(String[] args) throws IOException {
//    System.out.println("args = " + Arrays.toString(args));
//    final CommandLine parsed = parse(args);
//    final String idName = parsed.getOptionValue(ID_NAME_OPTION.getOpt());
//    final Path inputPath = Path.of(parsed.getOptionValue(INPUT_PATH_OPTION.getOpt()));
//    final Path outputPath = Path.of(parsed.getOptionValue(OUTPUT_PATH_OPTION.getOpt()));
//
////    final Path inputPath = Path.of("/Users/charles/code/airbyte/airbyte-config/init/src/main/resources/destinations.yaml");
////    final Path outputPath = Path.of("/Users/charles/code/airbyte/airbyte-config/init/src/main/resources/config/STANDARD_DESTINATION_DEFINITION");
//
//    new RepositorySeed().run(idName, inputPath, outputPath);
//  }

}
