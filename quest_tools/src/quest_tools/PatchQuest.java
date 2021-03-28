package quest_tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.file.FileSystem;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class PatchQuest {
	
	public static void main(String[] args) throws IOException {
		InputStream index = PatchQuest.class.getClassLoader().getResourceAsStream("patch_index.txt");
		if ( index == null ) throw new FileNotFoundException("patch_index.txt");
		FilePatcher patcher = new FilePatcher("java_quest.solarus");
		new BufferedReader(new InputStreamReader(index, "ISO-8859-1"))
			.lines()
			.map(PatchQuest::toPatchEntry)
			.forEach( patcher::patchEntry );
	}
	
	private static PatchEntry toPatchEntry(String str) {
		PatchEntry entry = new PatchEntry();
		String[] col = str.split(" ");
		entry.crc = col[0];
		entry.path = col[1];
		return entry;
	}
	


}

class PatchEntry {
	String crc;
	String path;
}

class FilePatcher {
	Path questFile;
	
	FilePatcher(String path) throws IOException {
		this.questFile = Paths.get(path);
	}
	
	public void patchEntry(PatchEntry entry) {
		// ZipEntry zipentry = questFile.getEntry(entry.path);

		try (ZipFile zf = new ZipFile(questFile.toFile())) {
			ZipEntry zentry = zf.getEntry(entry.path);
			if ( zentry != null ) {
				String actual = Long.toHexString(zentry.getCrc());
				if ( !actual.equals(entry.crc) ) {
					System.err.println("(skip) actual CRC["+actual+"] does not match expected ["+entry.crc+"] on "+entry.path);
					return;
				}
			}
		} catch (IOException e) {
			System.err.println("Unable to check CRC " + entry.path +": " + e.getMessage());
		}
		try (FileSystem fs = FileSystems.newFileSystem(questFile, null)) {
			Path target = fs.getPath(entry.path);
			InputStream source = this.getClass().getClassLoader().getResourceAsStream(entry.path);
			if ( source == null ) {
				System.err.println("Unable to open patch entry " + entry.path);
				return;
			}
			System.out.println("Patch " + entry.path );
			streamCopy(source, target);
			source.close();
		} catch (IOException e) {
			System.err.println("Unable to patch " + entry.path +": " + e.getMessage());
		}
	}
	
	private void streamCopy(InputStream in, Path target) throws IOException {
		byte[] buffer = new byte[10000];
		try (OutputStream out = Files.newOutputStream(target)) {
			for ( int read = in.read(buffer); read > 0; read = in.read(buffer) ) {
				out.write(buffer, 0, read);
			}
		}
	}
	
}