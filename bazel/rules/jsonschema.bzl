load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")



JSONSCHEMA2POJO_NAME = "jsonschema2pojo"
JSONSCHEMA2POJO_TAG = "1.0.2"
JSONSCHEMA2POJO_SHA = "158e927558e3ae4779dc2b7cd00e2010e43465af5a5aebdb55c889ccacb4d6e3"



def _format_maven_jar_name(group_id, artifact_id):
    """
    group_id: str
    artifact_id: str
    """
    return ("%s_%s" % (group_id, artifact_id)).replace(".", "_").replace("-", "_")

def _format_maven_jar_dep_name(group_id, artifact_id, repo_name = "maven"):
    """
    group_id: str
    artifact_id: str
    repo_name: str = "maven"
    """
    return "@%s//:%s" % (repo_name, _format_maven_jar_name(group_id, artifact_id))


AVRO_TOOLS_LABEL = Label(_format_maven_jar_dep_name(
                           group_id = AVRO_TOOLS[0],
                           artifact_id = AVRO_TOOLS[1],
                           repo_name = MAVEN_REPO_NAME))

AVRO_CORE_LABEL = Label(_format_maven_jar_dep_name(
                     group_id = AVRO[0],
                     artifact_id = AVRO[1],
                     repo_name = MAVEN_REPO_NAME))

AVRO_LIBS_LABELS = {
    'tools': AVRO_TOOLS_LABEL,
    'core': AVRO_CORE_LABEL
}

def _join_list(l, delimiter):
    """
    Join a list into a single string. Inverse of List#split()
    l: List[String]
    delimiter: String
    """
    joined = ""
    for item in l:
        joined += (item + delimiter)
    return joined

def _files(files):
    if not files:
        return ""
    return " ".join([f.path for f in files])


def _common_dir(dirs):
    if not dirs:
        return ""

    if len(dirs) == 1:
        return dirs[0]

    split_dirs = [dir.split("/") for dir in dirs]

    shortest = min(split_dirs)
    longest = max(split_dirs)

    for i, piece in enumerate(shortest):
        # if the next dir does not match, we've found our common parent
        if piece != longest[i]:
            return _join_list(shortest[:i], "/")

    return _join_list(shortest, "/")

def jsonschema2pojo_binary():
    """
    version: str = "1.9.1" - the version of avro to fetch
    """   
    http_archive(
        name = "jsonschema2pojo",
        strip_prefix = "jsonschema2pojo-%s" % JSONSCHEMA2POJO_TAG,
        sha256 = JSONSCHEMA2POJO_SHA,
        url = "https://github.com/joelittlejohn/jsonschema2pojo/releases/download/jsonschema2pojo-%s/jsonschema2pojo-%s.tar.gz" % (JSONSCHEMA2POJO_TAG, JSONSCHEMA2POJO_TAG),
    )

def _new_generator_command(ctx, src_dir, gen_dir):
  java_path = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_executable_exec_path
  gen_command  = "{java} -jar {tool} compile ".format(
     java=java_path,
     tool=ctx.file.avro_tools.path,
  )

  if ctx.attr.strings:
    gen_command += " -string"

  if ctx.attr.encoding:
    gen_command += " -encoding {encoding}".format(
      encoding=ctx.attr.encoding
    )

  gen_command += " schema {src} {gen_dir}".format(
    src=src_dir,
    gen_dir=gen_dir
  )

  return gen_command

def _impl(ctx):
    src_dir = _files(ctx.files.srcs) if ctx.attr.files_not_dirs else _common_dir([f.dirname for f in ctx.files.srcs])

    gen_dir = "{out}-tmp".format(
         out=ctx.outputs.codegen.path
    )

    commands = [
        "mkdir -p {gen_dir}".format(gen_dir=gen_dir),
        _new_generator_command(ctx, src_dir, gen_dir),
        # forcing a timestamp for deterministic artifacts
        "find {gen_dir} -exec touch -t 198001010000 {{}} \;".format(
          gen_dir=gen_dir
        ),
        "{jar} cMf {output} -C {gen_dir} .".format(
          jar="%s/bin/jar" % ctx.attr._jdk[java_common.JavaRuntimeInfo].java_home,
          output=ctx.outputs.codegen.path,
          gen_dir=gen_dir
        )
    ]

    inputs = ctx.files.srcs + ctx.files._jdk + [
      ctx.file.avro_tools,
    ]

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [ctx.outputs.codegen],
        command = " && ".join(commands),
        progress_message = "generating avro srcs",
        arguments = [],
      )

    return struct(
      codegen=ctx.outputs.codegen
    )

avro_gen = rule(
    attrs = {
        "srcs": attr.label_list(
          allow_files = [".avsc"]
        ),
        "strings": attr.bool(),
        "encoding": attr.string(),
        "files_not_dirs": attr.bool(
            default = False
        ),
        "_jdk": attr.label(
                    default=Label("@bazel_tools//tools/jdk:current_java_runtime"),
                    providers = [java_common.JavaRuntimeInfo]
                ),
        "avro_tools": attr.label(
            cfg = "host",
            default = AVRO_LIBS_LABELS["tools"],
            allow_single_file = True,
        )
    },
    outputs = {
        "codegen": "%{name}_codegen.srcjar",
    },
    implementation = _impl,
)


def avro_java_library(
  name, srcs=[], strings=None, encoding=None, visibility=None, files_not_dirs=False, avro_libs=None):
    libs = avro_libs if avro_libs else AVRO_LIBS_LABELS
    tools = libs["tools"]
    deps = [libs["core"]]

    avro_gen(
        name=name + '_srcjar',
        srcs = srcs,
        strings=strings,
        encoding=encoding,
        files_not_dirs=files_not_dirs,
        visibility=visibility,
        avro_tools=tools
    )
    native.java_library(
        name=name,
        srcs=[name + '_srcjar'],
        deps = deps,
        visibility=visibility,
    )